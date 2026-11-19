import 'package:gip/business/componentes/info_tienda/servicio_conciliacion.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Controller del caso de uso CUS-23 Conciliar datos sincronizados (proceso
/// automático, sin actor): lo dispara la app al terminar cada sincronización
/// (DA-48, DA-68). No contiene reglas de negocio.
class ConciliarCoordinator {
  ConciliarCoordinator(this._servicioConciliacion);

  final ServicioConciliacion _servicioConciliacion;

  /// Llama a servicioConciliacion.conciliar(tienda, desde) y devuelve los
  /// conflictos nuevos para el indicador de RNF-09. [desde] es la fecha del
  /// registro más antiguo que llegó al sincronizar. No exige propietario: lo
  /// corre la app, no una persona.
  Future<List<ConflictoSincronizacion>> ejecutar(
    Tienda tienda,
    DateTime desde,
  ) => _servicioConciliacion.conciliar(tienda, desde);
}
