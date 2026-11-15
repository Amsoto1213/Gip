import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gip/business/workflow/gestion_inventario/generar_alertas_diarias_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';

/// Dispara CUS-24 Generar alertas de reabastecimiento (actor Tiempo) en cuanto
/// hay usuario activo, por inicio de sesión o por sesión guardada: una vez por
/// tienda y día en cada arranque de la app (DI-25). No bloquea la pantalla:
/// la ejecución corre aparte y un fallo solo se anota en el registro, porque
/// la consulta (CUS-05) muestra lo último calculado. Como aún no existe la
/// sincronización (CUS-23), no espera a sincronizar; `reemplazar` evita
/// duplicados si se calcula otra vez el mismo día.
class DisparadorAlertasDiarias {
  DisparadorAlertasDiarias(
    this._sesion,
    this._coordinador, {
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now {
    _sesion.addListener(_revisar);
    _revisar();
  }

  final IniciarSesionViewModel _sesion;
  final GenerarAlertasDiariasCoordinator _coordinador;
  final DateTime Function() _reloj;
  final Set<String> _ejecutadas = {};

  /// Última ejecución lanzada; la usan las pruebas para esperarla.
  @visibleForTesting
  Future<void>? ultimaEjecucion;

  void _revisar() {
    final activo = _sesion.usuarioActivo;
    if (activo == null) return;
    final ahora = _reloj();
    final clave =
        '${activo.tienda.getId()}_${ahora.year}-${ahora.month}-${ahora.day}';
    if (!_ejecutadas.add(clave)) return;
    final ejecucion = _coordinador
        .ejecutar(activo.tienda, ahora)
        .catchError(
          (Object error) =>
              debugPrint('No se pudieron generar las alertas: $error'),
        );
    ultimaEjecucion = ejecucion;
    unawaited(ejecucion);
  }

  void dispose() => _sesion.removeListener(_revisar);
}
