import 'package:go_router/go_router.dart';
import 'package:gip/presentation/vender/vender_view.dart';

const rutaPrincipalVender = '/vender';

/// Rama de la sección Vender en la navegación principal. Las pantallas de la
/// sección se agregan aquí como rutas hijas.
StatefulShellBranch ramaVender() => StatefulShellBranch(
  routes: [
    GoRoute(path: rutaPrincipalVender, builder: (_, _) => const VenderView()),
  ],
);
