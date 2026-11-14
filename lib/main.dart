import 'package:flutter/material.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/composition_root/registrar_acceso.dart';
import 'package:gip/data/service_agents/cliente_supabase.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/acceso/puerta_acceso_view.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/transversal/configuracion/configuracion_supabase.dart';
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

class GipApp extends StatelessWidget {
  const GipApp({super.key, required this.iniciarSesion});

  final IniciarSesionCoordinator iniciarSesion;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          IniciarSesionViewModel(iniciarSesion)..verificarSesionGuardada(),
      child: MaterialApp(
        title: 'GIP',
        theme: TemaGip.claro(),
        home: const PuertaAccesoView(),
      ),
    );
  }
}
