import 'package:go_router/go_router.dart';
import 'package:gip/presentation/surtido/surtido_view.dart';

const rutaPrincipalSurtido = '/surtido';

/// Rama de la sección Surtido en la navegación principal. Las pantallas de la
/// sección se agregan aquí como rutas hijas.
StatefulShellBranch ramaSurtido() => StatefulShellBranch(
  routes: [
    GoRoute(path: rutaPrincipalSurtido, builder: (_, _) => const SurtidoView()),
  ],
);
