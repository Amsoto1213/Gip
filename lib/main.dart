import 'package:flutter/material.dart';
import 'package:gip/business/workflow/gestion_inventario/gestionar_producto_coordinator.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/composition_root/registrar_acceso.dart';
import 'package:gip/composition_root/registrar_inventario.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/service_agents/cliente_supabase.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/router.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/transversal/configuracion/configuracion_supabase.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Composition Root del GIP: único lugar que conoce las clases concretas de data/.
/// Los módulos se registran desde composition_root/.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cliente = await ClienteSupabase(
    const ConfiguracionSupabase.desdeEntorno(),
  ).inicializar();
  final base = BaseLocalDrift.abrir();
  final unidadTrabajo = UnidadTrabajoDrift(base);
  final inventario = registrarInventario(base, unidadTrabajo);
  runApp(
    GipApp(
      iniciarSesion: registrarAcceso(cliente),
      gestionarProducto: inventario.gestionarProducto,
    ),
  );
}

class GipApp extends StatefulWidget {
  const GipApp({
    super.key,
    required this.iniciarSesion,
    required this.gestionarProducto,
  });

  final IniciarSesionCoordinator iniciarSesion;
  final GestionarProductoCoordinator gestionarProducto;

  @override
  State<GipApp> createState() => _GipAppState();
}

class _GipAppState extends State<GipApp> {
  late final IniciarSesionViewModel _sesion = IniciarSesionViewModel(
    widget.iniciarSesion,
  )..verificarSesionGuardada();
  late final GoRouter _router = crearRouter(_sesion);

  @override
  void dispose() {
    _router.dispose();
    _sesion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _sesion),
        Provider.value(value: widget.gestionarProducto),
      ],
      child: MaterialApp.router(
        title: 'GIP',
        theme: TemaGip.claro(),
        routerConfig: _router,
      ),
    );
  }
}
