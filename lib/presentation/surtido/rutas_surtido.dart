import 'package:flutter/widgets.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/workflow/gestion_inventario/buscar_producto_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/consultar_existencias_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/gestionar_producto_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_conteo_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_entrada_mercancia_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_perdida_coordinator.dart';
import 'package:gip/presentation/comun/datos_actualizados.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/menu_lateral.dart';
import 'package:gip/presentation/surtido/buscar_producto_view.dart';
import 'package:gip/presentation/surtido/buscar_producto_view_model.dart';
import 'package:gip/presentation/surtido/conteo_view.dart';
import 'package:gip/presentation/surtido/conteo_view_model.dart';
import 'package:gip/presentation/surtido/entrada_mercancia_view.dart';
import 'package:gip/presentation/surtido/entrada_mercancia_view_model.dart';
import 'package:gip/presentation/surtido/existencias_view_model.dart';
import 'package:gip/presentation/surtido/perdida_view.dart';
import 'package:gip/presentation/surtido/perdida_view_model.dart';
import 'package:gip/presentation/surtido/producto_view.dart';
import 'package:gip/presentation/surtido/producto_view_model.dart';
import 'package:gip/presentation/surtido/surtido_view.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const rutaPrincipalSurtido = '/surtido';

/// Pantalla Producto (CUS-18). Sin `extra` crea un producto nuevo; con un
/// [Producto] en `extra` lo edita (así la abrirá CUS-06, DI-16). Con un texto
/// en `extra` crea uno nuevo que lleva asociado ese código leído (CUS-17).
const rutaProducto = '$rutaPrincipalSurtido/producto';

/// Pantalla Buscar producto (CUS-06, por nombre). Con [ModoBusqueda] en
/// `extra` decide si al tocar un resultado abre [rutaProducto] para editar
/// (por defecto) o lo devuelve (seleccionar, DI-20). Con [conCamara] abre la
/// cámara al entrar (CUS-17).
const rutaBuscarProducto = '$rutaPrincipalSurtido/buscar';

/// Pantalla Entrada de mercancía (CUS-01).
const rutaEntradaMercancia = '$rutaPrincipalSurtido/entrada';

/// Pantalla Pérdida o devolución (CUS-03).
const rutaPerdida = '$rutaPrincipalSurtido/perdida';

/// Pantalla Conteo físico (CUS-04).
const rutaConteo = '$rutaPrincipalSurtido/conteo';

/// Subsecciones de Surtido en el menú lateral: solo las que ya tienen
/// pantalla (DI-23). Existencias es la pantalla principal de la sección
/// (CUS-25, DI-32).
const subseccionesSurtido = <Subseccion>[
  (etiqueta: 'Existencias', ruta: rutaPrincipalSurtido),
  (etiqueta: 'Entrada de mercancía', ruta: rutaEntradaMercancia),
  (etiqueta: 'Pérdida o devolución', ruta: rutaPerdida),
  (etiqueta: 'Conteo físico', ruta: rutaConteo),
];

/// Rama de la sección Surtido en la navegación principal. Las pantallas de la
/// sección se agregan aquí como rutas hijas.
StatefulShellBranch ramaSurtido() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: rutaPrincipalSurtido,
      builder: (context, _) => ChangeNotifierProvider(
        create: (context) => ExistenciasViewModel(
          context.read<ConsultarExistenciasCoordinator>(),
          context.read<IniciarSesionViewModel>().usuarioActivo!.tienda,
        )..cargar(),
        child: RecargarAlCambiarLosDatos<ExistenciasViewModel>(
          alRecargar: (vm) => vm.cargar(),
          child: const SurtidoView(),
        ),
      ),
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
              abrirCamara: pideCamara(state),
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
          path: 'conteo',
          builder: (context, _) => ChangeNotifierProvider(
            create: (context) => ConteoViewModel(
              context.read<RegistrarConteoCoordinator>(),
              context.read<IniciarSesionViewModel>().usuarioActivo!.tienda,
            )..cargar(),
            child: const ConteoView(),
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
              codigoLeido: state.extra is String
                  ? state.extra! as String
                  : null,
            ),
            child: const ProductoView(),
          ),
        ),
      ],
    ),
  ],
);

/// Abre la pantalla Buscar producto. Termina al volver.
Future<void> abrirBuscarProducto(BuildContext context) =>
    context.push<void>(rutaBuscarProducto);

/// Abre Buscar producto con la cámara abierta (botón del lector, CUS-17).
/// Termina al volver.
Future<void> leerCodigoEnSurtido(BuildContext context) =>
    context.push<void>(conCamara(rutaBuscarProducto));

/// Abre la pantalla Producto para crear uno nuevo; con [codigoLeido], el
/// producto nuevo lo lleva asociado (CUS-17 → CUS-18). Termina al volver.
Future<void> abrirProductoNuevo(BuildContext context, {String? codigoLeido}) =>
    context.push<void>(rutaProducto, extra: codigoLeido);

/// Abre la pantalla Producto para editar [producto] (CUS-06 → CUS-18). Termina
/// al volver.
Future<void> abrirProductoParaEditar(BuildContext context, Producto producto) =>
    context.push<void>(rutaProducto, extra: producto);

/// Abre Buscar producto para elegir uno (CUS-06 → CUS-01, CUS-03). Termina con el
/// producto elegido, o null si el tendero volvió sin elegir.
Future<Producto?> elegirProducto(BuildContext context) =>
    context.push<Producto>(rutaBuscarProducto, extra: ModoBusqueda.seleccionar);

/// Abre la pantalla Entrada de mercancía. Termina al volver.
Future<void> abrirEntradaMercancia(BuildContext context) =>
    context.push<void>(rutaEntradaMercancia);

/// Abre la pantalla Pérdida o devolución. Termina al volver.
Future<void> abrirPerdida(BuildContext context) =>
    context.push<void>(rutaPerdida);

/// Abre la pantalla Conteo físico. Termina al volver.
Future<void> abrirConteo(BuildContext context) =>
    context.push<void>(rutaConteo);
