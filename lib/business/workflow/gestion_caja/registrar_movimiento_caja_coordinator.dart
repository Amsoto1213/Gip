import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';

/// Controller del caso de uso CUS-11 Registrar movimiento de caja: recibe la
/// operación del sistema desde la presentación y delega; no contiene reglas de
/// negocio. Solo el propietario anota movimientos (RNF-12).
class RegistrarMovimientoCajaCoordinator {
  RegistrarMovimientoCajaCoordinator(this._servicioCaja, this._servicioAcceso);

  final ServicioCaja _servicioCaja;
  final ServicioAcceso _servicioAcceso;

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioCaja.registrarMovimientoManual. Si no es el propietario lanza
  /// `ExcepcionSoloPropietario` y no escribe nada.
  Future<MovimientoCaja> registrarMovimiento(
    Tienda tienda,
    TipoMovimientoCaja tipo,
    ClasificacionMovimiento clasificacion,
    Decimal valor,
    String descripcion,
    Usuario usuario,
  ) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioCaja.registrarMovimientoManual(
      tienda,
      tipo,
      clasificacion,
      valor,
      descripcion,
    );
  }

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioCaja.consultarCajaDelDia(tienda): la caja de hoy con sus
  /// movimientos y su base de apertura, para mostrar la lista y las cifras
  /// (DI-38).
  Future<Caja> consultarCajaDelDia(Tienda tienda, Usuario usuario) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioCaja.consultarCajaDelDia(tienda);
  }
}
