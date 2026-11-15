import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
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
/// `formas_pago` con columna `tipo` (DI-21).
class VentaRepositorioDrift implements IVentaRepositorio {
  VentaRepositorioDrift(this._base);

  final BaseLocalDrift _base;

  static const _tablaVentas = 'ventas';
  static const _tablaFormas = 'formas_pago';

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
  /// (CUS-10, DI-29). El fiado se arma con su cliente, sin abonos: el reporte
  /// solo necesita el monto que cubre.
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
    return [
      for (final v in filas)
        Venta(v.id, porVenta[v.id] ?? const [], v.total, v.fecha),
    ];
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
    return {
      for (final r in await consulta.get())
        r.readTable(f).id: MapeoFiado.aEntidad(
          r.readTable(f),
          Cliente(
            r.readTable(c).id,
            r.readTable(c).nombre,
            r.readTable(c).telefono,
          ),
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
