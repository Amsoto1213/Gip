import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/pagos/servicio_ventas.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

/// Controller del caso de uso CUS-02 Registrar venta: recibe las operaciones
/// del sistema desde la presentación y las delega en [ServicioVentas], una
/// llamada por operación. No guarda estado: las líneas y las formas de pago
/// las conserva la pantalla (DA-54, DA-57).
class RegistrarVentaCoordinator {
  RegistrarVentaCoordinator(this._servicioVentas);

  final ServicioVentas _servicioVentas;

  /// Suma la cantidad si el producto ya está y bloquea si no hay existencia
  /// (RN-01). La línea queda en [lineas].
  Future<LineaVenta> agregarProducto(
    Tienda tienda,
    List<LineaVenta> lineas,
    Producto producto,
    Decimal cantidad,
  ) => _servicioVentas.agregarLinea(tienda, lineas, producto, cantidad);

  /// Vuelve a verificar la existencia (RN-01).
  void cambiarCantidad(LineaVenta linea, Decimal cantidad) =>
      _servicioVentas.cambiarCantidad(linea, cantidad);

  Decimal obtenerTotal(List<LineaVenta> lineas) =>
      _servicioVentas.calcularTotal(lineas);

  /// La pantalla muestra pago.getCambio() y lo conserva hasta confirmar.
  PagoContado pagarDeContado(Decimal montoACubrir, Decimal montoRecibido) =>
      _servicioVentas.crearPagoContado(montoACubrir, montoRecibido);

  /// La pantalla lo conserva hasta confirmar.
  PagoNequi pagarConNequi(Decimal monto, String? referencia) =>
      _servicioVentas.crearPagoNequi(monto, referencia);

  /// Guarda la venta con sus salidas y pagos en una transacción (RD-07).
  Future<Venta> confirmarVenta(
    Tienda tienda,
    List<LineaVenta> lineas,
    List<FormaPago> formasPago,
  ) => _servicioVentas.confirmar(tienda, lineas, formasPago);
}
