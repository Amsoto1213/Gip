import 'package:flutter/material.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/pantalla_seccion.dart';
import 'package:provider/provider.dart';

/// Sección Negocio (pendiente: ver `docs/ui/pantallas.md`). Por ahora solo
/// tiene "Cerrar sesión" (DI-05); al salir, el router vuelve al acceso.
class NegocioView extends StatelessWidget {
  const NegocioView({super.key});

  @override
  Widget build(BuildContext context) => PantallaSeccion(
    titulo: 'Negocio',
    hijos: [
      const SizedBox(height: 24),
      Align(
        alignment: Alignment.centerLeft,
        child: BotonSecundario(
          key: const Key('negocio_cerrar_sesion'),
          texto: 'Cerrar sesión',
          icono: Icons.logout,
          onPressed: () =>
              context.read<IniciarSesionViewModel>().cerrarSesion(),
        ),
      ),
    ],
  );
}
