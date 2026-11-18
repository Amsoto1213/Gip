import 'package:go_router/go_router.dart';
import 'package:gip/business/workflow/gestion_caja/registrar_movimiento_caja_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/caja/caja_view.dart';
import 'package:gip/presentation/caja/caja_view_model.dart';
import 'package:provider/provider.dart';

const rutaPrincipalCaja = '/caja';

/// Rama de la sección Caja en la navegación principal. Las pantallas de la
/// sección se agregan aquí como rutas hijas.
StatefulShellBranch ramaCaja() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: rutaPrincipalCaja,
      builder: (context, _) => ChangeNotifierProvider(
        create: (context) => CajaViewModel(
          context.read<RegistrarMovimientoCajaCoordinator>(),
          context.read<IniciarSesionViewModel>().usuarioActivo!,
        ),
        child: const CajaView(),
      ),
    ),
  ],
);
