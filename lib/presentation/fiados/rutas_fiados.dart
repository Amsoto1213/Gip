import 'package:flutter/material.dart';
import 'package:gip/business/workflow/pagos/consultar_cliente_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_abono_coordinator.dart';
import 'package:gip/presentation/comun/datos_actualizados.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/fiados/abono_view.dart';
import 'package:gip/presentation/fiados/abono_view_model.dart';
import 'package:gip/presentation/fiados/cliente_view.dart';
import 'package:gip/presentation/fiados/fiados_view.dart';
import 'package:gip/presentation/fiados/fiados_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const rutaPrincipalFiados = '/fiados';

/// Pantalla del cliente (CUS-19 mínimo, mockup `Cliente`), en el móvil. Recibe
/// el [FiadosViewModel] en `extra`; en la web el cliente se ve en la misma
/// página.
const rutaCliente = '$rutaPrincipalFiados/cliente';

/// Registrar abono (CUS-08, mockup `mAbono`), en el móvil. Recibe el
/// [FiadosViewModel] en `extra` y termina con verdadero si el abono quedó
/// guardado.
const rutaAbono = '$rutaCliente/abono';

/// Rama de la sección Fiados en la navegación principal. El
/// [FiadosViewModel] vive en la ruta principal y se pasa a las pantallas
/// hijas en `extra`, así la lista, la búsqueda y el cliente elegido se
/// conservan al ir y volver.
StatefulShellBranch ramaFiados() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: rutaPrincipalFiados,
      builder: (context, _) => ChangeNotifierProvider(
        create: (context) => FiadosViewModel(
          context.read<ConsultarClienteCoordinator>(),
          context.read<IniciarSesionViewModel>().usuarioActivo!.tienda,
        )..cargar(),
        child: RecargarAlCambiarLosDatos<FiadosViewModel>(
          alRecargar: (vm) => vm.recargar(),
          child: const FiadosView(),
        ),
      ),
      routes: [
        GoRoute(
          path: 'cliente',
          builder: (context, state) => ChangeNotifierProvider.value(
            value: state.extra! as FiadosViewModel,
            child: const ClienteView(),
          ),
          routes: [
            GoRoute(
              path: 'abono',
              builder: (context, state) {
                final fiados = state.extra! as FiadosViewModel;
                return MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: fiados),
                    ChangeNotifierProvider(
                      create: (context) => AbonoViewModel(
                        context.read<RegistrarAbonoCoordinator>(),
                        context
                            .read<IniciarSesionViewModel>()
                            .usuarioActivo!
                            .tienda,
                        fiados.elegido!,
                      ),
                    ),
                  ],
                  child: const AbonoView(),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Abre la pantalla del cliente elegido (móvil).
Future<void> abrirCliente(BuildContext context, FiadosViewModel vm) =>
    context.push(rutaCliente, extra: vm);

/// Abre Registrar abono del cliente elegido (móvil). Termina con verdadero si
/// el abono quedó guardado.
Future<bool> abrirAbono(BuildContext context, FiadosViewModel vm) async =>
    await context.push<bool>(rutaAbono, extra: vm) ?? false;
