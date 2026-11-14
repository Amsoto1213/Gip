import 'package:go_router/go_router.dart';
import 'package:gip/presentation/negocio/negocio_view.dart';

const rutaPrincipalNegocio = '/negocio';

/// Rama de la sección Negocio en la navegación principal. Las pantallas de la
/// sección se agregan aquí como rutas hijas.
StatefulShellBranch ramaNegocio() => StatefulShellBranch(
  routes: [
    GoRoute(path: rutaPrincipalNegocio, builder: (_, _) => const NegocioView()),
  ],
);
