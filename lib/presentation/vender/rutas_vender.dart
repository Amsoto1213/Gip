import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/workflow/gestion_inventario/buscar_producto_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_fiado_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_venta_perdida_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_venta_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/surtido/buscar_producto_view.dart';
import 'package:gip/presentation/surtido/buscar_producto_view_model.dart';
import 'package:gip/presentation/vender/cobrar_view.dart';
import 'package:gip/presentation/vender/cobrar_view_model.dart';
import 'package:gip/presentation/vender/fiar_view.dart';
import 'package:gip/presentation/vender/fiar_view_model.dart';
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

/// Fiar parte de la venta (CUS-07, mockup `mFiar`), en el móvil. Recibe
/// [DatosFiar] en `extra` y termina con el [Fiado] preparado, o null. En la
/// web es un diálogo sobre Cobrar (`wFiar`): ver [abrirFiar].
const rutaFiar = '$rutaCobrar/fiar';

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
          context.read<RegistrarVentaPerdidaCoordinator>(),
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
            child: const BuscarProductoView(
              modo: ModoBusqueda.seleccionar,
              seccion: 'Vender',
            ),
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
          routes: [
            GoRoute(
              path: 'fiar',
              builder: (context, state) => ChangeNotifierProvider(
                create: (context) =>
                    _fiarViewModel(context, state.extra! as DatosFiar),
                child: const FiarView(),
              ),
            ),
          ],
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

/// Abre Fiar: en el móvil como pantalla ([rutaFiar]) y en la web como diálogo
/// sobre Cobrar (`wFiar`). Termina con el fiado preparado, o null si el
/// tendero canceló.
Future<Fiado?> abrirFiar(BuildContext context, DatosFiar datos) {
  if (!FormaGip.esWeb(context)) {
    return context.push<Fiado>(rutaFiar, extra: datos);
  }
  final vm = _fiarViewModel(context, datos);
  return showDialog<Fiado>(
    context: context,
    barrierColor: Theme.of(context).colorScheme.scrim,
    builder: (_) => ChangeNotifierProvider.value(
      value: vm,
      child: const FiarView(enDialogo: true),
    ),
  ).whenComplete(vm.dispose);
}

FiarViewModel _fiarViewModel(BuildContext context, DatosFiar datos) =>
    FiarViewModel(
      context.read<RegistrarFiadoCoordinator>(),
      context.read<IniciarSesionViewModel>().usuarioActivo!.tienda,
      datos,
    );
