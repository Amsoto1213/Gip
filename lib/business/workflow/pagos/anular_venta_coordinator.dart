import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/pagos/servicio_ventas.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/pagos/anulacion_venta.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

/// Controller del caso de uso CUS-20 Anular venta: recibe las operaciones del
/// sistema desde la presentación y delega; no contiene reglas de negocio. Solo
/// el propietario lista y anula ventas (RNF-12, RNF-15). La confirmación
/// explícita la pide la pantalla antes de llamar a [anularVenta].
class AnularVentaCoordinator {
  AnularVentaCoordinator(this._servicioVentas, this._servicioAcceso);

  final ServicioVentas _servicioVentas;
  final ServicioAcceso _servicioAcceso;

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioVentas.listarVentas(tienda, desde, hasta).
  Future<List<Venta>> listarVentas(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
    Usuario usuario,
  ) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioVentas.listarVentas(tienda, desde, hasta);
  }

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioVentas.listarSalidas: los productos de cada venta, por el id de
  /// la venta. No está en EA (DI-39).
  Future<Map<String, List<SalidaVenta>>> listarProductos(
    Tienda tienda,
    List<Venta> ventas,
    Usuario usuario,
  ) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioVentas.listarSalidas(tienda, ventas);
  }

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioVentas.anular(tienda, venta, motivo, usuario) (RNF-15).
  Future<AnulacionVenta> anularVenta(
    Tienda tienda,
    Venta venta,
    String motivo,
    Usuario usuario,
  ) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioVentas.anular(tienda, venta, motivo, usuario);
  }
}
