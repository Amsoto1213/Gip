import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/info_tienda/servicio_conciliacion.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';

/// Controller del caso de uso CUS-22 Revisar conflictos de sincronización:
/// muestra los conflictos pendientes y aplica la decisión del propietario
/// (DA-48, DA-66). No contiene reglas de negocio; cada operación exige que
/// quien la pide sea el propietario (RNF-12).
class RevisarConflictosCoordinator {
  RevisarConflictosCoordinator(
    this._servicioConciliacion,
    this._servicioAcceso,
  );

  final ServicioConciliacion _servicioConciliacion;
  final ServicioAcceso _servicioAcceso;

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioConciliacion.obtenerConflictos(tienda) (RNF-12). Si no es el
  /// propietario lanza `ExcepcionSoloPropietario`.
  Future<List<ConflictoSincronizacion>> consultarConflictos(
    Tienda tienda,
    Usuario usuario,
  ) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioConciliacion.obtenerConflictos(tienda);
  }

  /// Llama a servicioAcceso.exigirPropietario(usuario) y luego a
  /// servicioConciliacion.resolverConflicto(tienda, conflicto, idsElegidos).
  Future<void> resolver(
    Tienda tienda,
    ConflictoSincronizacion conflicto,
    List<String> idsElegidos,
    Usuario usuario,
  ) async {
    _servicioAcceso.exigirPropietario(usuario);
    return _servicioConciliacion.resolverConflicto(
      tienda,
      conflicto,
      idsElegidos,
    );
  }
}
