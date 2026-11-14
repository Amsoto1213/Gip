import 'package:drift/drift.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/pagos/i_venta_repositorio.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/data/local/base_local_drift.dart';

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
