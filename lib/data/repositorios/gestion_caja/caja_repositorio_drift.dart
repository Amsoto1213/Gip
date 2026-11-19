import 'package:drift/drift.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_caja/i_caja_repositorio.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/data/local/base_local_drift.dart';

/// [ICajaRepositorio] sobre la base local (drift). Toda consulta filtra por
/// `tienda_id`. La caja y sus movimientos solo se agregan (DA-48, DA-62).
class CajaRepositorioDrift implements ICajaRepositorio {
  CajaRepositorioDrift(this._base);

  final BaseLocalDrift _base;

  static const _tablaCajas = 'cajas';
  static const _tablaMovimientos = 'movimientos_caja';

  /// Nombres que comparte con los enums de Supabase.
  static const _tipos = {
    TipoMovimientoCaja.ingreso: 'INGRESO',
    TipoMovimientoCaja.egreso: 'EGRESO',
  };
  static const _clasificaciones = {
    ClasificacionMovimiento.negocio: 'NEGOCIO',
    ClasificacionMovimiento.personal: 'PERSONAL',
    ClasificacionMovimiento.anulacion: 'ANULACION',
  };

  /// Día como texto "AAAA-MM-DD" (DI-21).
  static String _textoDia(DateTime dia) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dia.year}-${dos(dia.month)}-${dos(dia.day)}';
  }

  static DateTime _leerDia(String texto) {
    final partes = texto.split('-').map(int.parse).toList();
    return DateTime(partes[0], partes[1], partes[2]);
  }

  @override
  Future<Caja?> buscarPorFecha(Tienda tienda, DateTime fecha) async {
    final fila =
        await (_base.select(_base.cajas)..where(
              (c) =>
                  c.tiendaId.equals(tienda.getId()) &
                  c.fecha.equals(_textoDia(fecha)),
            ))
            .getSingleOrNull();
    if (fila == null) return null;
    return _armar(tienda, fila);
  }

  /// Caja de la tienda con ese id, con todos sus movimientos (también los que
  /// llegaron después del cierre) y los datos de su cierre (CUS-22, DI-45).
  /// Filtra por `tienda_id`.
  @override
  Future<Caja?> buscarPorId(Tienda tienda, String id) async {
    final fila =
        await (_base.select(_base.cajas)..where(
              (c) => c.tiendaId.equals(tienda.getId()) & c.id.equals(id),
            ))
            .getSingleOrNull();
    if (fila == null) return null;
    return _armar(tienda, fila);
  }

  /// La caja más reciente con fecha anterior a [fecha] (DI-38). Las fechas son
  /// texto "AAAA-MM-DD", que ordena igual que los días.
  @override
  Future<Caja?> buscarUltimaAnterior(Tienda tienda, DateTime fecha) async {
    final fila =
        await (_base.select(_base.cajas)
              ..where(
                (c) =>
                    c.tiendaId.equals(tienda.getId()) &
                    c.fecha.isSmallerThanValue(_textoDia(fecha)),
              )
              ..orderBy([(c) => OrderingTerm.desc(c.fecha)])
              ..limit(1))
            .getSingleOrNull();
    if (fila == null) return null;
    return _armar(tienda, fila);
  }

  Future<Caja> _armar(Tienda tienda, FilaCaja fila) async {
    final movimientos =
        await (_base.select(_base.movimientosCaja)
              ..where(
                (m) =>
                    m.tiendaId.equals(tienda.getId()) &
                    m.cajaId.equals(fila.id),
              )
              ..orderBy([(m) => OrderingTerm.asc(m.fecha)]))
            .get();
    final tipos = _tipos.map((k, v) => MapEntry(v, k));
    final clasificaciones = _clasificaciones.map((k, v) => MapEntry(v, k));
    return Caja(
      fila.id,
      _leerDia(fila.fecha),
      baseApertura: fila.baseApertura,
      movimientos: [
        for (final m in movimientos)
          MovimientoCaja(
            m.id,
            m.valor,
            m.descripcion,
            clasificaciones[m.clasificacion]!,
            tipos[m.tipo]!,
            m.fecha,
          ),
      ],
      efectivoContado: fila.cerrada ? fila.efectivoContado : null,
      diferencia: fila.cerrada ? fila.diferencia : null,
      fechaCierre: fila.cerrada ? fila.fechaCierre : null,
    );
  }

  /// Inserta la caja si su id no existe y, solo entonces, la anota en
  /// `cola_pendientes` (DA-33, DA-62). Se une a la transacción abierta.
  @override
  Future<void> crear(Tienda tienda, Caja caja) => _base.transaction(() async {
    final existe = await (_base.select(
      _base.cajas,
    )..where((c) => c.id.equals(caja.getId()))).getSingleOrNull();
    if (existe != null) return;
    await _base
        .into(_base.cajas)
        .insert(
          CajasCompanion.insert(
            id: caja.getId(),
            tiendaId: tienda.getId(),
            fecha: _textoDia(caja.getFecha()),
            baseApertura: Value(caja.getBaseApertura()),
          ),
        );
    await anotarEnCola(
      _base,
      tiendaId: tienda.getId(),
      tabla: _tablaCajas,
      registroId: caja.getId(),
      operacion: OperacionCola.insertar,
    );
  });

  /// Inserta solo el movimiento y lo anota en `cola_pendientes` en la misma
  /// transacción (DA-33). Se une a la transacción abierta.
  @override
  Future<void> registrarMovimiento(
    Tienda tienda,
    Caja caja,
    MovimientoCaja movimiento,
  ) => _base.transaction(() async {
    await _base
        .into(_base.movimientosCaja)
        .insert(
          MovimientosCajaCompanion.insert(
            id: movimiento.getId(),
            tiendaId: tienda.getId(),
            cajaId: caja.getId(),
            tipo: _tipos[movimiento.getTipo()]!,
            clasificacion: _clasificaciones[movimiento.getClasificacion()]!,
            valor: movimiento.getValor(),
            descripcion: movimiento.getDescripcion(),
            fecha: movimiento.getFecha(),
          ),
        );
    await anotarEnCola(
      _base,
      tiendaId: tienda.getId(),
      tabla: _tablaMovimientos,
      registroId: movimiento.getId(),
      operacion: OperacionCola.insertar,
    );
  });

  /// Guarda solo el cierre de la caja y lo anota en `cola_pendientes` como
  /// ACTUALIZAR en la misma transacción (DA-33, RF-13). No toca los
  /// movimientos. Se une a la transacción abierta.
  @override
  Future<void> cerrar(Tienda tienda, Caja caja) => _base.transaction(() async {
    await (_base.update(_base.cajas)..where(
          (c) => c.id.equals(caja.getId()) & c.tiendaId.equals(tienda.getId()),
        ))
        .write(
          CajasCompanion(
            cerrada: const Value(true),
            efectivoContado: Value(caja.getEfectivoContado()),
            diferencia: Value(caja.getDiferencia()),
            fechaCierre: Value(caja.getFechaCierre()),
          ),
        );
    await anotarEnCola(
      _base,
      tiendaId: tienda.getId(),
      tabla: _tablaCajas,
      registroId: caja.getId(),
      operacion: OperacionCola.actualizar,
    );
  });

  /// Movimientos de todas las cajas de la tienda con fecha en `[desde, hasta)`
  /// (CUS-10, DI-29).
  @override
  Future<List<MovimientoCaja>> listarMovimientos(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async {
    final filas =
        await (_base.select(_base.movimientosCaja)
              ..where(
                (m) =>
                    m.tiendaId.equals(tienda.getId()) &
                    m.fecha.isBiggerOrEqualValue(desde.toUtc()) &
                    m.fecha.isSmallerThanValue(hasta.toUtc()),
              )
              ..orderBy([(m) => OrderingTerm.asc(m.fecha)]))
            .get();
    final tipos = _tipos.map((k, v) => MapEntry(v, k));
    final clasificaciones = _clasificaciones.map((k, v) => MapEntry(v, k));
    return [
      for (final m in filas)
        MovimientoCaja(
          m.id,
          m.valor,
          m.descripcion,
          clasificaciones[m.clasificacion]!,
          tipos[m.tipo]!,
          m.fecha,
        ),
    ];
  }
}
