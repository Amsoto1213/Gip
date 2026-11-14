import 'package:flutter/widgets.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/workflow/gestion_inventario/gestionar_producto_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/surtido/producto_view.dart';
import 'package:gip/presentation/surtido/producto_view_model.dart';
import 'package:gip/presentation/surtido/surtido_view.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const rutaPrincipalSurtido = '/surtido';

/// Pantalla Producto (CUS-18). Sin `extra` crea un producto nuevo; con un
/// [Producto] en `extra` lo edita (así la abrirá CUS-06, DI-16).
const rutaProducto = '$rutaPrincipalSurtido/producto';

/// Rama de la sección Surtido en la navegación principal. Las pantallas de la
/// sección se agregan aquí como rutas hijas.
StatefulShellBranch ramaSurtido() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: rutaPrincipalSurtido,
      builder: (_, _) => const SurtidoView(),
      routes: [
        GoRoute(
          path: 'producto',
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => ProductoViewModel(
              context.read<GestionarProductoCoordinator>(),
              context.read<IniciarSesionViewModel>().usuarioActivo!.tienda,
              producto: state.extra is Producto
                  ? state.extra! as Producto
                  : null,
            ),
            child: const ProductoView(),
          ),
        ),
      ],
    ),
  ],
);

/// Abre la pantalla Producto para crear uno nuevo.
void abrirProductoNuevo(BuildContext context) => context.push(rutaProducto);
