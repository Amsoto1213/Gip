import 'package:gip/business/workflow/gestion_caja/registrar_cierre_caja_coordinator.dart';
import 'package:gip/business/workflow/gestion_caja/registrar_movimiento_caja_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/caja/caja_view.dart';
import 'package:gip/presentation/caja/caja_view_model.dart';
import 'package:gip/presentation/caja/cierre_caja_view.dart';
import 'package:gip/presentation/caja/cierre_caja_view_model.dart';
import 'package:gip/presentation/comun/menu_lateral.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const rutaPrincipalCaja = '/caja';

/// Pantalla Cierre de caja (CUS-14).
const rutaCierreCaja = '$rutaPrincipalCaja/cierre';

/// Subsecciones de Caja en el menú lateral: solo las que ya tienen pantalla
/// (DI-23). "Ventas de hoy" llega con CUS-20.
const subseccionesCaja = <Subseccion>[
  (etiqueta: 'Movimientos', ruta: rutaPrincipalCaja),
  (etiqueta: 'Cierre de caja', ruta: rutaCierreCaja),
];

/// Rama de la sección Caja en la navegación principal. Las pantallas de la
/// sección se agregan aquí como rutas hijas.
StatefulShellBranch ramaCaja() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: rutaPrincipalCaja,
      builder: (context, _) => ChangeNotifierProvider(
        create: (context) => CajaViewModel(
          context.read<RegistrarMovimientoCajaCoordinator>(),
          context.read<RegistrarCierreCajaCoordinator>(),
          context.read<IniciarSesionViewModel>().usuarioActivo!,
        )..cargarSaldo(),
        child: const CajaView(),
      ),
      routes: [
        GoRoute(
          path: 'cierre',
          builder: (context, _) => ChangeNotifierProvider(
            create: (context) => CierreCajaViewModel(
              context.read<RegistrarCierreCajaCoordinator>(),
              context.read<IniciarSesionViewModel>().usuarioActivo!,
            )..cargar(),
            child: const CierreCajaView(),
          ),
        ),
      ],
    ),
  ],
);
