import 'package:gip/business/componentes/info_tienda/resolutor_conflicto.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/i_unidad_trabajo.dart';
import 'package:gip/business/interfaces/info_tienda/i_conflicto_repositorio.dart';
import 'package:gip/transversal/errores/errores_conciliacion.dart';

/// Pure Fabrication e Information Expert de la conciliación: muestra los
/// choques que debe decidir el propietario y aplica su decisión (RNF-08,
/// ERS 3.2.1 c, DA-48).
///
/// Tiene lo de CUS-22: [obtenerConflictos] y [resolverConflicto]. `conciliar` y
/// los `detectar*`, que crean los conflictos al sincronizar, llegan con CUS-23
/// junto con las demás dependencias de EA (movimientos, fiados, cajas,
/// productos e inventario); aquí solo recibe lo que usa (DI-28, DI-45).
class ServicioConciliacion {
  ServicioConciliacion(
    this._conflictos,
    this._unidadTrabajo,
    List<ResolutorConflicto> resolutores,
  ) : _resolutores = List.unmodifiable(resolutores);

  final IConflictoRepositorio _conflictos;
  final IUnidadTrabajo _unidadTrabajo;
  final List<ResolutorConflicto> _resolutores;

  /// Llama a conflictos.listarPendientes(tienda).
  Future<List<ConflictoSincronizacion>> obtenerConflictos(Tienda tienda) =>
      _conflictos.listarPendientes(tienda);

  /// Dentro de unidadTrabajo.ejecutar llama a
  /// `resolutorPara(conflicto).resolver(tienda, conflicto, idsElegidos)`,
  /// luego a `conflicto.setResuelto(true)` y a
  /// `conflictos.marcarResuelto(tienda, conflicto)` (DA-66). Si algo falla, no
  /// se guarda nada y el conflicto sigue sin resolver, también en memoria.
  ///
  /// Rechaza con [ExcepcionConflictoYaResuelto] un conflicto que ya estaba
  /// resuelto, para no aplicar dos veces la decisión (por ejemplo, devolver dos
  /// veces un abono), y con [ExcepcionConflictoSinResolutor] uno de un tipo que
  /// ningún resolutor atiende (DI-45).
  Future<void> resolverConflicto(
    Tienda tienda,
    ConflictoSincronizacion conflicto,
    List<String> idsElegidos,
  ) async {
    if (conflicto.isResuelto()) throw const ExcepcionConflictoYaResuelto();
    final resolutor = _resolutorPara(conflicto);
    try {
      await _unidadTrabajo.ejecutar(() async {
        await resolutor.resolver(tienda, conflicto, idsElegidos);
        conflicto.setResuelto(true);
        await _conflictos.marcarResuelto(tienda, conflicto);
      });
    } catch (_) {
      conflicto.setResuelto(false);
      rethrow;
    }
  }

  /// Recorre los resolutores y devuelve el primero cuyo `admite(conflicto)` es
  /// verdadero; rechaza si ninguno lo admite (Polymorphism).
  ResolutorConflicto _resolutorPara(ConflictoSincronizacion conflicto) {
    for (final resolutor in _resolutores) {
      if (resolutor.admite(conflicto)) return resolutor;
    }
    throw const ExcepcionConflictoSinResolutor();
  }
}
