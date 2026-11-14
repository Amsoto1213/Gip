import 'package:flutter/material.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:provider/provider.dart';

/// Decide qué se muestra al abrir la app: el inicio de sesión o, si ya hay
/// usuario activo, la pantalla de inicio. Cuando exista `router.dart` esta
/// decisión pasa a un redirect de go_router (DI-01).
class PuertaAccesoView extends StatelessWidget {
  const PuertaAccesoView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IniciarSesionViewModel>();
    if (vm.verificandoSesion) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final activo = vm.usuarioActivo;
    if (activo == null) return const IniciarSesionView();
    return _InicioProvisional(
      nombre: activo.usuario.getNombre(),
      tienda: activo.tienda.getNombre(),
      esPropietario: activo.usuario is Administrador,
    );
  }
}

/// Pantalla provisional hasta que exista la navegación de 5 secciones.
class _InicioProvisional extends StatelessWidget {
  const _InicioProvisional({
    required this.nombre,
    required this.tienda,
    required this.esPropietario,
  });

  final String nombre;
  final String tienda;
  final bool esPropietario;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hola, $nombre', style: tema.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(tienda, style: tema.textTheme.titleMedium),
            Text(
              esPropietario ? 'Propietario' : 'Empleado',
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
