import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';

/// Controller del caso de uso CUS-14 Registrar cierre de caja: recibe las
/// operaciones del sistema desde la presentación y delega; no contiene reglas
/// de negocio. Solo el propietario consulta el saldo y cierra (RNF-12).
class RegistrarCierreCajaCoordinator {
  RegistrarCierreCajaCoordinator(this._servicioCaja, this._servicioAcceso);

  final ServicioCaja _servicioCaja;
  final ServicioAcceso _servicioAcceso;

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioCaja.consultarSaldoEsperado(tienda).
  Future<Decimal> consultarSaldoEsperado(Tienda tienda, Usuario usuario) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioCaja.consultarSaldoEsperado(tienda);
  }

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioCaja.cerrarCaja(tienda, efectivoContado): devuelve el faltante
  /// (negativo) o el sobrante (positivo) (RF-13).
  Future<Decimal> cerrarCaja(
    Tienda tienda,
    Decimal efectivoContado,
    Usuario usuario,
  ) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioCaja.cerrarCaja(tienda, efectivoContado);
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
