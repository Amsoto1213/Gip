import 'package:flutter/widgets.dart';
import 'package:gip/business/workflow/gestion_caja/consultar_margen_coordinator.dart';
import 'package:gip/business/workflow/gestion_caja/consultar_rotacion_coordinator.dart';
import 'package:gip/business/workflow/gestion_caja/generar_reporte_diario_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/consultar_alertas_coordinator.dart';
import 'package:gip/business/workflow/info_tienda/exportar_datos_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/menu_lateral.dart';
import 'package:gip/presentation/negocio/alertas_view.dart';
import 'package:gip/presentation/negocio/alertas_view_model.dart';
import 'package:gip/presentation/negocio/exportar_view.dart';
import 'package:gip/presentation/negocio/exportar_view_model.dart';
import 'package:gip/presentation/negocio/margen_view.dart';
import 'package:gip/presentation/negocio/margen_view_model.dart';
import 'package:gip/presentation/negocio/negocio_view.dart';
import 'package:gip/presentation/negocio/reporte_diario_view.dart';
import 'package:gip/presentation/negocio/reporte_diario_view_model.dart';
import 'package:gip/presentation/negocio/rotacion_view.dart';
import 'package:gip/presentation/negocio/rotacion_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const rutaPrincipalNegocio = '/negocio';

/// Pantalla Alertas de surtido (CUS-05).
const rutaAlertas = '$rutaPrincipalNegocio/alertas';

/// Pantalla Ganancia por producto (CUS-09).
const rutaMargen = '$rutaPrincipalNegocio/ganancia';

/// Pantalla Reporte del día (CUS-10).
const rutaReporte = '$rutaPrincipalNegocio/reporte';

/// Pantalla Rotación de productos (CUS-12).
const rutaRotacion = '$rutaPrincipalNegocio/rotacion';

/// Pantalla Exportar datos (CUS-16).
const rutaExportar = '$rutaPrincipalNegocio/exportar';

/// Subsecciones de Negocio en el menú lateral: solo las que ya tienen
/// pantalla (DI-23). Se listan para todos; al empleado la pantalla le dice que
/// la consulta es solo para el propietario (CUS-05, paso 7).
const subseccionesNegocio = <Subseccion>[
  (etiqueta: 'Alertas de surtido', ruta: rutaAlertas),
  (etiqueta: 'Reporte del día', ruta: rutaReporte),
  (etiqueta: 'Ganancia por producto', ruta: rutaMargen),
  (etiqueta: 'Rotación', ruta: rutaRotacion),
  (etiqueta: 'Exportar datos', ruta: rutaExportar),
];

/// Rama de la sección Negocio en la navegación principal. Las pantallas de la
/// sección se agregan aquí como rutas hijas.
StatefulShellBranch ramaNegocio() => StatefulShellBranch(
  routes: [
    GoRoute(
      path: rutaPrincipalNegocio,
      builder: (_, _) => const NegocioView(),
      routes: [
        GoRoute(
          path: 'alertas',
          builder: (context, _) => ChangeNotifierProvider(
            create: (context) => AlertasViewModel(
              context.read<ConsultarAlertasCoordinator>(),
              context.read<IniciarSesionViewModel>().usuarioActivo!,
            )..cargar(),
            child: const AlertasView(),
          ),
        ),
        GoRoute(
          path: 'ganancia',
          builder: (context, _) => ChangeNotifierProvider(
            create: (context) => MargenViewModel(
              context.read<ConsultarMargenCoordinator>(),
              context.read<IniciarSesionViewModel>().usuarioActivo!,
            )..cargar(),
            child: const MargenView(),
          ),
        ),
        GoRoute(
          path: 'rotacion',
          builder: (context, _) => ChangeNotifierProvider(
            create: (context) => RotacionViewModel(
              context.read<ConsultarRotacionCoordinator>(),
              context.read<IniciarSesionViewModel>().usuarioActivo!,
            )..cargar(),
            child: const RotacionView(),
          ),
        ),
        GoRoute(
          path: 'exportar',
          builder: (context, _) => ChangeNotifierProvider(
            create: (context) => ExportarViewModel(
              context.read<ExportarDatosCoordinator>(),
              context.read<IniciarSesionViewModel>().usuarioActivo!,
            ),
            child: const ExportarView(),
          ),
        ),
        GoRoute(
          path: 'reporte',
          builder: (context, _) => ChangeNotifierProvider(
            create: (context) => ReporteDiarioViewModel(
              context.read<GenerarReporteDiarioCoordinator>(),
              context.read<IniciarSesionViewModel>().usuarioActivo!,
            )..cargar(),
            child: const ReporteDiarioView(),
          ),
        ),
      ],
    ),
  ],
);

/// Abre la pantalla Alertas de surtido.
void abrirAlertas(BuildContext context) => context.push(rutaAlertas);

/// Abre la pantalla Reporte del día.
void abrirReporte(BuildContext context) => context.push(rutaReporte);

/// Abre la pantalla Ganancia por producto.
void abrirMargen(BuildContext context) => context.push(rutaMargen);

/// Abre la pantalla Rotación de productos.
void abrirRotacion(BuildContext context) => context.push(rutaRotacion);

/// Abre la pantalla Exportar datos.
void abrirExportar(BuildContext context) => context.push(rutaExportar);
