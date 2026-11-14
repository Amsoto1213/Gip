import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/pagos/procesador_pago.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

/// Pago de contado: el dinero entra a la caja del negocio (RF-02, RF-10).
class ProcesadorPagoContado implements ProcesadorPago {
  ProcesadorPagoContado(this._servicioCaja);

  final ServicioCaja _servicioCaja;

  @override
  bool admite(FormaPago forma) => forma is PagoContado;

  /// Entra lo recibido menos el cambio: forma.calcularMontoCubierto().
  @override
  Future<void> procesar(Tienda tienda, Venta venta, FormaPago forma) =>
      _servicioCaja.registrarIngreso(
        tienda,
        forma.calcularMontoCubierto(),
        'Venta ${venta.getId()}',
      );

  /// El dinero sale de la caja de hoy como ANULACION (CUS-20).
  @override
  Future<void> revertir(Tienda tienda, Venta venta, FormaPago forma) =>
      _servicioCaja.registrarMovimiento(
        tienda,
        TipoMovimientoCaja.egreso,
        ClasificacionMovimiento.anulacion,
        forma.calcularMontoCubierto(),
        'Anulacion venta ${venta.getId()}',
      );
}
