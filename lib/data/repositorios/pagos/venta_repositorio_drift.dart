import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/anulacion_venta.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/pagos/i_venta_repositorio.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/pagos/mapeo_fiado.dart';

/// [IVentaRepositorio] sobre la base local (drift). La venta y sus formas de
/// pago solo se agregan (RNF-15); las formas van en la tabla única
/// `formas_pago` con columna `tipo` (DI-21). La anulación es una fila aparte en
/// `anulaciones_venta` y no modifica la venta (CUS-20, DI-39).
class VentaRepositorioDrift implements IVentaRepositorio {
  VentaRepositorioDrift(this._base);

  final BaseLocalDrift _base;

  static const _tablaVentas = 'ventas';
  static const _tablaFormas = 'formas_pago';
  static const _tablaAnulaciones = 'anulaciones_venta';

  /// Inserta la venta y sus formas de pago, y anota cada fila en
  /// `cola_pendientes` en la misma transacción (DA-33). Se une a la
  /// transacción abierta: las salidas y la caja van en la misma (RNF-04).
  @override
  Future<void> guardar(Tienda tienda, Venta venta) => _base.transaction(
    () async {
      await _base
          .into(_base.ventas)
          .insert(
            VentasCompanion.insert(
              id: venta.getId(),
              tiendaId: tienda.getId(),
              fecha: venta.getFecha(),
              total: venta.getTotal(),
            ),
          );
      await _anotar(tienda, _tablaVentas, venta.getId());
      for (final forma in venta.getFormasPago()) {
        await _base.into(_base.formasPago).insert(_fila(tienda, venta, forma));
        await _anotar(tienda, _tablaFormas, forma.getId());
      }
    },
  );

  /// Ventas de la tienda con fecha en `[desde, hasta)` con sus formas de pago
  /// (CUS-10, DI-29), con su anulación si la tiene. El fiado se arma con su
  /// cliente y sus abonos (CUS-20, DI-39).
  @override
  Future<List<Venta>> listarPorPeriodo(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async {
    final filas =
        await (_base.select(_base.ventas)
              ..where(
                (v) =>
                    v.tiendaId.equals(tienda.getId()) &
                    v.fecha.isBiggerOrEqualValue(desde.toUtc()) &
                    v.fecha.isSmallerThanValue(hasta.toUtc()),
              )
              ..orderBy([(v) => OrderingTerm.asc(v.fecha)]))
            .get();
    if (filas.isEmpty) return const [];
    final ids = filas.map((v) => v.id).toList();
    final formas =
        await (_base.select(_base.formasPago)..where(
              (f) => f.tiendaId.equals(tienda.getId()) & f.ventaId.isIn(ids),
            ))
            .get();
    final fiados = await _fiadosDe(tienda, formas);
    final porVenta = <String, List<FormaPago>>{};
    for (final forma in formas) {
      final entidad = _formaDeFila(forma, fiados);
      if (entidad != null) {
        porVenta.putIfAbsent(forma.ventaId, () => []).add(entidad);
      }
    }
    final anulaciones = await _anulacionesDe(tienda, ids);
    return [
      for (final v in filas)
        Venta(
          v.id,
          porVenta[v.id] ?? const [],
          v.total,
          v.fecha,
          anulacion: anulaciones[v.id],
        ),
    ];
  }

  /// Inserta la anulación y la anota en `cola_pendientes` en la misma
  /// transacción (DA-33); la venta no se toca (RNF-15). Se une a la
  /// transacción de ServicioVentas.anular.
  @override
  Future<void> registrarAnulacion(
    Tienda tienda,
    Venta venta,
    AnulacionVenta anulacion,
  ) => _base.transaction(() async {
    await _base
        .into(_base.anulacionesVenta)
        .insert(
          AnulacionesVentaCompanion.insert(
            id: anulacion.getId(),
            tiendaId: tienda.getId(),
            ventaId: venta.getId(),
            usuarioId: anulacion.getUsuarioId(),
            usuarioNombre: anulacion.getUsuarioNombre(),
            fecha: anulacion.getFecha(),
            motivo: anulacion.getMotivo(),
          ),
        );
    await _anotar(tienda, _tablaAnulaciones, anulacion.getId());
  });

  /// La anulación de cada venta, por el id de la venta; si hubiera dos (dos
  /// equipos sin conexión), vale la más antigua (DI-39). De quien anuló trae
  /// el id y el nombre guardados (DI-61).
  Future<Map<String, AnulacionVenta>> _anulacionesDe(
    Tienda tienda,
    List<String> ventaIds,
  ) async {
    final filas =
        await (_base.select(_base.anulacionesVenta)
              ..where(
                (a) =>
                    a.tiendaId.equals(tienda.getId()) &
                    a.ventaId.isIn(ventaIds),
              )
              ..orderBy([(a) => OrderingTerm.desc(a.fecha)]))
            .get();
    // Del más reciente al más antiguo: la última que se escribe es la más
    // antigua.
    return {
      for (final a in filas)
        a.ventaId: AnulacionVenta(
          a.id,
          a.usuarioId,
          a.usuarioNombre,
          a.fecha,
          a.motivo,
        ),
    };
  }

  Future<Map<String, Fiado>> _fiadosDe(
    Tienda tienda,
    List<FilaFormaPago> formas,
  ) async {
    final ids = [
      for (final f in formas)
        if (f.tipo == 'FIADO') f.id,
    ];
    if (ids.isEmpty) return const {};
    final f = _base.fiados;
    final c = _base.clientes;
    final consulta = _base.select(f).join([
      innerJoin(c, c.id.equalsExp(f.clienteId)),
    ])..where(f.tiendaId.equals(tienda.getId()) & f.id.isIn(ids));
    // Con sus abonos: para anular la venta hay que saber si el fiado ya tiene
    // (CUS-20, DI-39).
    final abonos =
        await (_base.select(_base.abonos)..where(
              (a) => a.tiendaId.equals(tienda.getId()) & a.fiadoId.isIn(ids),
            ))
            .get();
    final porFiado = <String, List<FilaAbono>>{};
    for (final a in abonos) {
      porFiado.putIfAbsent(a.fiadoId, () => []).add(a);
    }
    return {
      for (final r in await consulta.get())
        r.readTable(f).id: MapeoFiado.aEntidad(
          r.readTable(f),
          Cliente(
            r.readTable(c).id,
            r.readTable(c).nombre,
            r.readTable(c).telefono,
          ),
          porFiado[r.readTable(f).id] ?? const [],
        ),
    };
  }

  FormaPago? _formaDeFila(FilaFormaPago fila, Map<String, Fiado> fiados) =>
      switch (fila.tipo) {
        'CONTADO' => PagoContado(
          fila.id,
          fila.montoRecibido ?? Decimal.zero,
          fila.cambio ?? Decimal.zero,
        ),
        'NEQUI' => PagoNequi(
          fila.id,
          fila.monto ?? Decimal.zero,
          fila.referencia,
        ),
        'FIADO' => fiados[fila.id],
        _ => null,
      };

  FormasPagoCompanion _fila(Tienda tienda, Venta venta, FormaPago forma) =>
      switch (forma) {
        PagoContado() => FormasPagoCompanion.insert(
          id: forma.getId(),
          tiendaId: tienda.getId(),
          ventaId: venta.getId(),
          tipo: 'CONTADO',
          montoRecibido: Value(forma.getMontoRecibido()),
          cambio: Value(forma.getCambio()),
        ),
        PagoNequi() => FormasPagoCompanion.insert(
          id: forma.getId(),
          tiendaId: tienda.getId(),
          ventaId: venta.getId(),
          tipo: 'NEQUI',
          monto: Value(forma.getMonto()),
          referencia: Value(forma.getReferencia()),
        ),
        // El cliente y el saldo van en `fiados`, con el mismo id (DI-26).
        Fiado() => FormasPagoCompanion.insert(
          id: forma.getId(),
          tiendaId: tienda.getId(),
          ventaId: venta.getId(),
          tipo: 'FIADO',
          monto: Value(forma.getMontoInicial()),
        ),
        _ => throw UnsupportedError(
          'Forma de pago no disponible todavía: ${forma.runtimeType}',
        ),
      };

  Future<void> _anotar(Tienda tienda, String tabla, String id) => anotarEnCola(
    _base,
    tiendaId: tienda.getId(),
    tabla: tabla,
    registroId: id,
    operacion: OperacionCola.insertar,
  );
}
