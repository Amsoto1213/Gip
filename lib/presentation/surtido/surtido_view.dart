import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/pantalla_seccion.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';

/// Sección Surtido (pendiente: ver `docs/ui/pantallas.md`). Por ahora abre
/// Entrada de mercancía (CUS-01), Pérdida o devolución (CUS-03), Buscar
/// producto (CUS-06) y Producto (CUS-18).
class SurtidoView extends StatelessWidget {
  const SurtidoView({super.key});

  @override
  Widget build(BuildContext context) => PantallaSeccion(
    titulo: 'Surtido',
    hijos: [
      const SizedBox(height: 24),
      FilledButton.icon(
        key: const Key('surtido_registrar_entrada'),
        onPressed: () => abrirEntradaMercancia(context),
        icon: const Icon(Icons.local_shipping_outlined),
        label: const Text('Registrar entrada'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        key: const Key('surtido_registrar_perdida'),
        onPressed: () => abrirPerdida(context),
        icon: const Icon(Icons.remove_circle_outline),
        label: const Text('Registrar pérdida'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => abrirBuscarProducto(context),
        icon: const Icon(Icons.search),
        label: const Text('Buscar producto'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => abrirProductoNuevo(context),
        icon: const Icon(Icons.add),
        label: const Text('Producto nuevo'),
      ),
    ],
  );
}
