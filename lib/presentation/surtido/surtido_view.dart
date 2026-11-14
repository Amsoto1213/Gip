import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/pantalla_seccion.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';

/// Sección Surtido (pendiente: ver `docs/ui/pantallas.md`). Por ahora solo
/// abre la pantalla Producto (CUS-18).
class SurtidoView extends StatelessWidget {
  const SurtidoView({super.key});

  @override
  Widget build(BuildContext context) => PantallaSeccion(
    titulo: 'Surtido',
    hijos: [
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => abrirProductoNuevo(context),
        icon: const Icon(Icons.add),
        label: const Text('Producto nuevo'),
      ),
    ],
  );
}
