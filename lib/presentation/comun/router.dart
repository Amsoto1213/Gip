import 'package:gip/presentation/acceso/iniciar_sesion_view.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/acceso/verificando_sesion_view.dart';
import 'package:gip/presentation/caja/rutas_caja.dart';
import 'package:gip/presentation/comun/marco_navegacion.dart';
import 'package:gip/presentation/fiados/rutas_fiados.dart';
import 'package:gip/presentation/negocio/rutas_negocio.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:gip/presentation/vender/rutas_vender.dart';
import 'package:go_router/go_router.dart';

const rutaVerificandoSesion = '/cargando';
const rutaIniciarSesion = '/entrar';

/// Navegación de la app (DI-01). Cada sección declara su rama en
/// `<seccion>/rutas_<seccion>.dart`; aquí solo se juntan, en el orden de la
/// barra. Sin usuario activo se va al inicio de sesión (DI-05).
GoRouter crearRouter(IniciarSesionViewModel sesion) => GoRouter(
  initialLocation: rutaPrincipalVender,
  refreshListenable: sesion,
  redirect: (context, state) {
    final ruta = state.matchedLocation;
    if (sesion.verificandoSesion) {
      return ruta == rutaVerificandoSesion ? null : rutaVerificandoSesion;
    }
    if (sesion.usuarioActivo == null) {
      return ruta == rutaIniciarSesion ? null : rutaIniciarSesion;
    }
    if (ruta == rutaIniciarSesion || ruta == rutaVerificandoSesion) {
      return rutaPrincipalVender;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: rutaVerificandoSesion,
      builder: (_, _) => const VerificandoSesionView(),
    ),
    GoRoute(
      path: rutaIniciarSesion,
      builder: (_, _) => const IniciarSesionView(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => MarcoNavegacion(shell: shell),
      branches: [
        ramaVender(),
        ramaSurtido(),
        ramaFiados(),
        ramaCaja(),
        ramaNegocio(),
      ],
    ),
  ],
);
