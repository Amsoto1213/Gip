import 'package:flutter/material.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/composition_root/registrar_acceso.dart';
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
  runApp(GipApp(iniciarSesion: registrarAcceso(cliente)));
}

class GipApp extends StatefulWidget {
  const GipApp({super.key, required this.iniciarSesion});

  final IniciarSesionCoordinator iniciarSesion;

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
    return ChangeNotifierProvider.value(
      value: _sesion,
      child: MaterialApp.router(
        title: 'GIP',
        theme: TemaGip.claro(),
        routerConfig: _router,
      ),
    );
  }
}
