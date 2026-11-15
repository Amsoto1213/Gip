import 'package:flutter/widgets.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/workflow/gestion_inventario/buscar_producto_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/gestionar_producto_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_entrada_mercancia_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_perdida_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/menu_lateral.dart';
import 'package:gip/presentation/surtido/buscar_producto_view.dart';
import 'package:gip/presentation/surtido/buscar_producto_view_model.dart';
import 'package:gip/presentation/surtido/entrada_mercancia_view.dart';
import 'package:gip/presentation/surtido/entrada_mercancia_view_model.dart';
import 'package:gip/presentation/surtido/perdida_view.dart';
import 'package:gip/presentation/surtido/perdida_view_model.dart';
import 'package:gip/presentation/surtido/producto_view.dart';
import 'package:gip/presentation/surtido/producto_view_model.dart';
import 'package:gip/presentation/surtido/surtido_view.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const rutaPrincipalSurtido = '/surtido';

/// Pantalla Producto (CUS-18). Sin `extra` crea un producto nuevo; con un
/// [Producto] en `extra` lo edita (así la abrirá CUS-06, DI-16).
const rutaProducto = '$rutaPrincipalSurtido/producto';

/// Pantalla Buscar producto (CUS-06, por nombre). Con [ModoBusqueda] en
/// `extra` decide si al tocar un resultado abre [rutaProducto] para editar
/// (por defecto) o lo devuelve (seleccionar, DI-20).
const rutaBuscarProducto = '$rutaPrincipalSurtido/buscar';

/// Pantalla Entrada de mercancía (CUS-01).
const rutaEntradaMercancia = '$rutaPrincipalSurtido/entrada';

/// Pantalla Pérdida o devolución (CUS-03).
const rutaPerdida = '$rutaPrincipalSurtido/perdida';

/// Subsecciones de Surtido en el menú lateral: solo las que ya tienen
/// pantalla (DI-23). Existencias llega con CUS-25 y Conteo físico con CUS-04.
const subseccionesSurtido = <Subseccion>[
  (etiqueta: 'Entrada de mercancía', ruta: rutaEntradaMercancia),
  (etiqueta: 'Pérdida o devolución', ruta: rutaPerdida),
];

/// Rama de la sección Surtido en la navegación principal. Las pantallas de la
/// sección se agregan aquí como rutas hijas.
StatefulShellBranch ramaSurtido() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: rutaPrincipalSurtido,
      builder: (_, _) => const SurtidoView(),
      routes: [
        GoRoute(
          path: 'buscar',
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => BuscarProductoViewModel(
              context.read<BuscarProductoCoordinator>(),
              context.read<IniciarSesionViewModel>().usuarioActivo!.tienda,
            ),
            child: BuscarProductoView(
              modo: state.extra is ModoBusqueda
                  ? state.extra! as ModoBusqueda
                  : ModoBusqueda.editar,
            ),
          ),
        ),
        GoRoute(
          path: 'entrada',
          builder: (context, _) => ChangeNotifierProvider(
            create: (context) => EntradaMercanciaViewModel(
              context.read<RegistrarEntradaMercanciaCoordinator>(),
              context.read<IniciarSesionViewModel>().usuarioActivo!.tienda,
            ),
            child: const EntradaMercanciaView(),
          ),
        ),
        GoRoute(
          path: 'perdida',
          builder: (context, _) => ChangeNotifierProvider(
            create: (context) => PerdidaViewModel(
              context.read<RegistrarPerdidaCoordinator>(),
              context.read<IniciarSesionViewModel>().usuarioActivo!.tienda,
            ),
            child: const PerdidaView(),
          ),
        ),
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

/// Abre la pantalla Buscar producto.
void abrirBuscarProducto(BuildContext context) =>
    context.push(rutaBuscarProducto);

/// Abre la pantalla Producto para crear uno nuevo. Termina al volver.
Future<void> abrirProductoNuevo(BuildContext context) =>
    context.push<void>(rutaProducto);

/// Abre la pantalla Producto para editar [producto] (CUS-06 → CUS-18). Termina
/// al volver.
Future<void> abrirProductoParaEditar(BuildContext context, Producto producto) =>
    context.push<void>(rutaProducto, extra: producto);

/// Abre Buscar producto para elegir uno (CUS-06 → CUS-01, CUS-03). Termina con el
/// producto elegido, o null si el tendero volvió sin elegir.
Future<Producto?> elegirProducto(BuildContext context) =>
    context.push<Producto>(rutaBuscarProducto, extra: ModoBusqueda.seleccionar);

/// Abre la pantalla Entrada de mercancía.
void abrirEntradaMercancia(BuildContext context) =>
    context.push(rutaEntradaMercancia);

/// Abre la pantalla Pérdida o devolución.
void abrirPerdida(BuildContext context) => context.push(rutaPerdida);
