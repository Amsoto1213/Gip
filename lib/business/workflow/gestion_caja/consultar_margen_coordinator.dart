import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_reportes.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';

/// Controller del caso de uso CUS-09 Consultar margen de ganancia: recibe la
/// operación del sistema desde la presentación y delega; no contiene reglas de
/// negocio. Solo el propietario consulta (RNF-12).
class ConsultarMargenCoordinator {
  ConsultarMargenCoordinator(this._servicioReportes, this._servicioAcceso);

  final ServicioReportes _servicioReportes;
  final ServicioAcceso _servicioAcceso;

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioReportes.calcularMargenes(tienda, desde, hasta). Valor nulo =
  /// dato incompleto. Si no es el propietario lanza `ExcepcionSoloPropietario`.
  Future<Map<Producto, Decimal?>> consultarMargen(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
    Usuario usuario,
  ) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioReportes.calcularMargenes(tienda, desde, hasta);
  }
}
