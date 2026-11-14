import 'package:go_router/go_router.dart';
import 'package:gip/presentation/caja/caja_view.dart';

const rutaPrincipalCaja = '/caja';

/// Rama de la sección Caja en la navegación principal. Las pantallas de la
/// sección se agregan aquí como rutas hijas.
StatefulShellBranch ramaCaja() => StatefulShellBranch(
  routes: [
    GoRoute(path: rutaPrincipalCaja, builder: (_, _) => const CajaView()),
  ],
);
