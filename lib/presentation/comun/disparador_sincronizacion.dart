import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';

/// Dispara la sincronización (CUS-23, actor Tiempo) mientras haya un usuario
/// activo (DI-47, DI-48):
/// - **al instante**: [espera] después de que este equipo escribe algo
///   ([escrituras]) o de que otro equipo cambia algo de la tienda
///   ([cambiosRemotos]); varios avisos seguidos se juntan en una sincronización;
/// - al iniciar sesión o abrir la app con la sesión guardada, al volver del
///   segundo plano y al recuperar la conexión;
/// - cada [intervalo] con la app abierta, como respaldo por si se perdió un
///   aviso.
///
/// No bloquea nada: la sincronización corre aparte y un fallo solo se anota en
/// el registro, porque la app funciona igual sin internet (RNF-08). No sabe
/// cómo se sincroniza ni de dónde vienen los avisos: recibe la función
/// [_sincronizar] y los flujos del Composition Root.
///
/// Los disparos seguidos se juntan: dos pedidos a menos de [separacion] hacen
/// una sola sincronización, salvo los de iniciar sesión, recuperar la conexión
/// y los avisos de escritura y de cambios, que siempre se intentan (el
/// Sincronizador ya une los que coinciden mientras corre uno).
class DisparadorSincronizacion with WidgetsBindingObserver {
  DisparadorSincronizacion(
    this._sesion,
    this._sincronizar, {
    Stream<List<ConnectivityResult>>? conexion,
    Stream<void>? escrituras,
    this._cambiosRemotos,
    this.intervalo = const Duration(minutes: 5),
    this.separacion = const Duration(seconds: 20),
    this.espera = const Duration(seconds: 1),
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now {
    _sesion.addListener(_revisarSesion);
    _escrituras = escrituras?.listen((_) => _pedirPronto(), onError: (_) {});
    WidgetsBinding.instance.addObserver(this);
    _suscripcion = (conexion ?? Connectivity().onConnectivityChanged).listen(
      _alCambiarConexion,
      onError: (_) {},
    );
    _revisarSesion();
  }

  final IniciarSesionViewModel _sesion;
  final Future<void> Function(Tienda tienda) _sincronizar;
  final Stream<void> Function(Tienda tienda)? _cambiosRemotos;
  final Duration intervalo;
  final Duration separacion;

  /// Cuánto se espera, después de un aviso, antes de sincronizar: así las
  /// escrituras seguidas (los cinco registros de una venta) hacen una sola.
  final Duration espera;
  final DateTime Function() _reloj;

  StreamSubscription<List<ConnectivityResult>>? _suscripcion;
  StreamSubscription<void>? _escrituras;
  StreamSubscription<void>? _remotos;
  Timer? _espera;
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
      _espera?.cancel();
      _espera = null;
      unawaited(_remotos?.cancel());
      _remotos = null;
      _tiendaActual = null;
      return;
    }
    final tienda = activo.tienda;
    if (_tiendaActual == tienda.getId()) return;
    _tiendaActual = tienda.getId();
    _temporizador?.cancel();
    _temporizador = Timer.periodic(intervalo, (_) => _lanzar());
    unawaited(_remotos?.cancel());
    _remotos = _cambiosRemotos
        ?.call(tienda)
        .listen((_) => _pedirPronto(), onError: (_) {});
    _lanzar(forzar: true);
  }

  /// Un aviso de que algo cambió, aquí o en otro equipo: se sincroniza dentro
  /// de [espera], juntando los avisos que lleguen mientras tanto.
  void _pedirPronto() {
    if (_sesion.usuarioActivo == null) return;
    _espera?.cancel();
    _espera = Timer(espera, () => _lanzar(forzar: true));
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
    _espera?.cancel();
    unawaited(_suscripcion?.cancel());
    unawaited(_escrituras?.cancel());
    unawaited(_remotos?.cancel());
  }
}
