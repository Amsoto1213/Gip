import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/info_tienda/revisar_conflictos_coordinator.dart';

/// Cuántos conflictos de sincronización están por revisar, para avisarle al
/// propietario (CUS-22, DI-50). Llama solo a [RevisarConflictosCoordinator]. Si
/// quien lo pide no es el propietario, o falla la consulta, el total es cero y
/// el aviso no sale.
class ConflictosPendientesViewModel extends ChangeNotifier {
  ConflictosPendientesViewModel(this._coordinador, this._usuarioActivo);

  final RevisarConflictosCoordinator _coordinador;
  final UsuarioActivo _usuarioActivo;

  int _total = 0;
  int _consulta = 0;

  /// Conflictos sin resolver.
  int get total => _total;

  /// Vuelve a contar los conflictos pendientes.
  Future<void> cargar() async {
    final consulta = ++_consulta;
    var total = 0;
    try {
      total = (await _coordinador.consultarConflictos(
        _usuarioActivo.tienda,
        _usuarioActivo.usuario,
      )).length;
    } catch (_) {
      total = 0;
    }
    if (consulta != _consulta) return;
    _total = total;
    notifyListeners();
  }
}
