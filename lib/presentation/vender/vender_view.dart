import 'package:flutter/material.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/pantalla_seccion.dart';
import 'package:provider/provider.dart';

/// Sección Vender (pendiente: CUS-02, mockups `Main` y `Vender`).
class VenderView extends StatelessWidget {
  const VenderView({super.key});

  @override
  Widget build(BuildContext context) {
    final nombre = context.select<IniciarSesionViewModel, String?>(
      (vm) => vm.usuarioActivo?.usuario.getNombre(),
    );
    return PantallaSeccion(
      titulo: 'Vender',
      saludo: nombre == null ? null : 'Hola, $nombre',
    );
  }
}
