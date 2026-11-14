import 'package:go_router/go_router.dart';
import 'package:gip/presentation/fiados/fiados_view.dart';

const rutaPrincipalFiados = '/fiados';

/// Rama de la sección Fiados en la navegación principal. Las pantallas de la
/// sección se agregan aquí como rutas hijas.
StatefulShellBranch ramaFiados() => StatefulShellBranch(
  routes: [
    GoRoute(path: rutaPrincipalFiados, builder: (_, _) => const FiadosView()),
  ],
);
