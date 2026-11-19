import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';

/// Dispara la sincronización (CUS-23, actor Tiempo) mientras haya un usuario
/// activo: al iniciar sesión o abrir la app con la sesión guardada, al volver
/// del segundo plano, al recuperar la conexión y cada [intervalo] con la app
/// abierta (DI-47). No bloquea nada: la sincronización corre aparte y un fallo
/// solo se anota en el registro, porque la app funciona igual sin internet
/// (RNF-08). No sabe cómo se sincroniza: recibe la función [_sincronizar] del
/// Composition Root.
///
/// Los disparos seguidos se juntan: dos pedidos a menos de [separacion] hacen
/// una sola sincronización, salvo el de iniciar sesión y el de recuperar la
/// conexión, que siempre se intentan (el Sincronizador ya une los que
/// coinciden mientras corre uno).
class DisparadorSincronizacion with WidgetsBindingObserver {
  DisparadorSincronizacion(
    this._sesion,
    this._sincronizar, {
    Stream<List<ConnectivityResult>>? conexion,
    this.intervalo = const Duration(minutes: 5),
    this.separacion = const Duration(seconds: 20),
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now {
    _sesion.addListener(_revisarSesion);
    WidgetsBinding.instance.addObserver(this);
    _suscripcion = (conexion ?? Connectivity().onConnectivityChanged).listen(
      _alCambiarConexion,
      onError: (_) {},
    );
    _revisarSesion();
  }

  final IniciarSesionViewModel _sesion;
  final Future<void> Function(Tienda tienda) _sincronizar;
  final Duration intervalo;
  final Duration separacion;
  final DateTime Function() _reloj;

  StreamSubscription<List<ConnectivityResult>>? _suscripcion;
  Timer? _temporizador;
  String? _tiendaActual;
  DateTime? _ultimoInicio;

  /// Última sincronización lanzada; la usan las pruebas para esperarla.
  @visibleForTesting
  Future<void>? ultimaEjecucion;

  void _revisarSesion() {
    final activo = _sesion.usuarioActivo;
    if (activo == null) {
      _temporizador?.cancel();
      _temporizador = null;
      _tiendaActual = null;
      return;
    }
    final tienda = activo.tienda;
    if (_tiendaActual == tienda.getId()) return;
    _tiendaActual = tienda.getId();
    _temporizador?.cancel();
    _temporizador = Timer.periodic(intervalo, (_) => _lanzar());
    _lanzar(forzar: true);
  }

  void _alCambiarConexion(List<ConnectivityResult> estados) {
    if (estados.any((e) => e != ConnectivityResult.none)) {
      _lanzar(forzar: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _lanzar();
  }

  void _lanzar({bool forzar = false}) {
    final activo = _sesion.usuarioActivo;
    if (activo == null) return;
    final ahora = _reloj();
    final ultimo = _ultimoInicio;
    if (!forzar && ultimo != null && ahora.difference(ultimo) < separacion) {
      return;
    }
    _ultimoInicio = ahora;
    final ejecucion = _sincronizar(activo.tienda).catchError(
      (Object error) => debugPrint('No se pudo sincronizar: $error'),
    );
    ultimaEjecucion = ejecucion;
    unawaited(ejecucion);
  }

  void dispose() {
    _sesion.removeListener(_revisarSesion);
    WidgetsBinding.instance.removeObserver(this);
    _temporizador?.cancel();
    unawaited(_suscripcion?.cancel());
  }
}
