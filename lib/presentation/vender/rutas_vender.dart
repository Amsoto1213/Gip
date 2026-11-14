import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/workflow/gestion_inventario/buscar_producto_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_venta_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/surtido/buscar_producto_view.dart';
import 'package:gip/presentation/surtido/buscar_producto_view_model.dart';
import 'package:gip/presentation/vender/cobrar_view.dart';
import 'package:gip/presentation/vender/cobrar_view_model.dart';
import 'package:gip/presentation/vender/vender_view.dart';
import 'package:gip/presentation/vender/vender_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const rutaPrincipalVender = '/vender';

/// Buscar producto (CUS-06) en modo seleccionar, dentro de Vender: devuelve el
/// producto para agregarlo a la venta (DI-21).
const rutaBuscarParaVender = '$rutaPrincipalVender/buscar';

/// Pantalla Cobrar (CUS-02, mockup `Cobro`). Recibe [DatosCobro] en `extra` y
/// termina con verdadero si la venta quedó registrada.
const rutaCobrar = '$rutaPrincipalVender/cobrar';

/// Lo que Vender le pasa a Cobrar: las líneas de la venta y su total.
typedef DatosCobro = ({List<LineaVenta> lineas, Decimal total});

/// Rama de la sección Vender en la navegación principal. Las pantallas de la
/// sección se agregan aquí como rutas hijas. El [VenderViewModel] vive en la
/// ruta principal, así que la venta en curso se conserva al ir a buscar o a
/// cobrar y al cambiar de pestaña (DA-57).
StatefulShellBranch ramaVender() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: rutaPrincipalVender,
      builder: (context, _) => ChangeNotifierProvider(
        create: (context) => VenderViewModel(
          context.read<RegistrarVentaCoordinator>(),
          context.read<IniciarSesionViewModel>().usuarioActivo!.tienda,
        ),
        child: const VenderView(),
      ),
      routes: [
        GoRoute(
          path: 'buscar',
          builder: (context, _) => ChangeNotifierProvider(
            create: (context) => BuscarProductoViewModel(
              context.read<BuscarProductoCoordinator>(),
              context.read<IniciarSesionViewModel>().usuarioActivo!.tienda,
            ),
            child: const BuscarProductoView(modo: ModoBusqueda.seleccionar),
          ),
        ),
        GoRoute(
          path: 'cobrar',
          builder: (context, state) {
            final datos = state.extra! as DatosCobro;
            return ChangeNotifierProvider(
              create: (context) => CobrarViewModel(
                context.read<RegistrarVentaCoordinator>(),
                context.read<IniciarSesionViewModel>().usuarioActivo!.tienda,
                datos.lineas,
                datos.total,
              ),
              child: const CobrarView(),
            );
          },
        ),
      ],
    ),
  ],
);

/// Abre Buscar producto para agregar a la venta. Termina con el producto
/// elegido, o null si el tendero volvió sin elegir.
Future<Producto?> elegirProductoParaVender(BuildContext context) =>
    context.push<Producto>(rutaBuscarParaVender);

/// Abre Cobrar. Termina con verdadero si la venta quedó registrada.
Future<bool> abrirCobrar(BuildContext context, DatosCobro datos) async =>
    await context.push<bool>(rutaCobrar, extra: datos) ?? false;
