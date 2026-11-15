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

    final caja = Caja(fila.id, _leerDia(fila.fecha));
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
    for (final m in movimientos) {
      caja.registrarMovimiento(
        MovimientoCaja(
          m.id,
          m.valor,
          m.descripcion,
          clasificaciones[m.clasificacion]!,
          tipos[m.tipo]!,
          m.fecha,
        ),
      );
    }
    return caja;
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
