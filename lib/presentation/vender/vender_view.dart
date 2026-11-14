import 'package:flutter/material.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/pantalla_seccion.dart';
import 'package:gip/presentation/vender/rutas_vender.dart';
import 'package:gip/presentation/vender/vender_view_model.dart';
import 'package:provider/provider.dart';

/// Pantalla Vender (CUS-02, mockup `Main`): buscar producto, venta actual y
/// "Cobrar". Sin "Lo más vendido", existencias, lector ni aviso de
/// sincronización todavía (DI-21).
class VenderView extends StatelessWidget {
  const VenderView({super.key});

  Future<void> _buscar(BuildContext context) async {
    final vm = context.read<VenderViewModel>();
    final producto = await elegirProductoParaVender(context);
    if (producto != null) await vm.agregar(producto);
  }

  Future<void> _cobrar(BuildContext context) async {
    final vm = context.read<VenderViewModel>();
    final registrada = await abrirCobrar(context, (
      lineas: vm.lineas,
      total: vm.total,
    ));
    if (registrada) vm.ventaRegistrada();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VenderViewModel>();
    final nombre = context.select<IniciarSesionViewModel, String?>(
      (s) => s.usuarioActivo?.usuario.getNombre(),
    );
    final tema = Theme.of(context);
    final n = vm.lineas.length;

    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: PantallaSeccion(
            titulo: 'Vender',
            saludo: nombre == null ? null : 'Hola, $nombre',
            hijos: [
              const SizedBox(height: 16),
              _CampoBuscar(onTap: () => _buscar(context)),
              if (vm.error != null) ...[
                const SizedBox(height: 12),
                _Mensaje(texto: vm.error!, esError: true),
              ],
              if (vm.aviso != null) ...[
                const SizedBox(height: 12),
                _Mensaje(texto: vm.aviso!, esError: false),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Venta actual',
                        style: tema.textTheme.titleLarge,
                        children: [
                          TextSpan(
                            text: ' · $n ${n == 1 ? 'producto' : 'productos'}',
                            style: tema.textTheme.bodyLarge?.copyWith(
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (vm.hayLineas)
                    TextButton(
                      key: const Key('vender_vaciar'),
                      onPressed: vm.vaciar,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Text('Vaciar'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (!vm.hayLineas)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Busque un producto para empezar la venta',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyLarge?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, linea) in vm.lineas.indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        _FilaLinea(
                          linea: linea,
                          onSumar: () => vm.sumar(linea),
                          onRestar: () => vm.restar(linea),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilledButton(
                key: const Key('vender_cobrar'),
                onPressed: vm.hayLineas ? () => _cobrar(context) : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Row(
                  children: [
                    Text(
                      'Cobrar',
                      style: tema.textTheme.titleLarge?.copyWith(
                        color: vm.hayLineas ? tema.colorScheme.onPrimary : null,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$ ${mostrarPrecio(vm.total)}',
                      style: tema.textTheme.titleLarge?.copyWith(
                        color: vm.hayLineas ? tema.colorScheme.onPrimary : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoBuscar extends StatelessWidget {
  const _CampoBuscar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return OutlinedButton.icon(
      key: const Key('vender_buscar'),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        alignment: Alignment.centerLeft,
        backgroundColor: tema.colorScheme.surface,
        foregroundColor: tema.colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.search),
      label: Text('Buscar producto…', style: tema.textTheme.bodyLarge),
    );
  }
}

class _FilaLinea extends StatelessWidget {
  const _FilaLinea({
    required this.linea,
    required this.onSumar,
    required this.onRestar,
  });

  final LineaVenta linea;
  final VoidCallback onSumar;
  final VoidCallback onRestar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final producto = linea.getItem().getProducto();
    final id = producto.getId();
    Widget paso(String sufijo, IconData icono, String ayuda, VoidCallback f) =>
        IconButton.outlined(
          key: Key('vender_${sufijo}_$id'),
          onPressed: f,
          tooltip: ayuda,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: Icon(icono),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(producto.getNombre(), style: tema.textTheme.titleMedium),
                Text(
                  '\$ ${mostrarPrecio(producto.getPrecioVenta())} c/u',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          paso('menos', Icons.remove, 'Quitar uno', onRestar),
          SizedBox(
            width: 44,
            child: Text(
              mostrarPrecio(linea.getCantidad()),
              key: Key('vender_cantidad_$id'),
              textAlign: TextAlign.center,
              style: tema.textTheme.titleMedium,
            ),
          ),
          paso('mas', Icons.add, 'Agregar uno', onSumar),
          SizedBox(
            width: 96,
            child: Text(
              '\$ ${mostrarPrecio(linea.calcularSubtotal())}',
              textAlign: TextAlign.end,
              style: tema.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso o error en línea, con los colores del tema.
class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.texto, required this.esError});

  final String texto;
  final bool esError;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: esError ? esquema.errorContainer : esquema.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            esError ? Icons.error_outline : Icons.check_circle_outline,
            color: esError ? esquema.error : esquema.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: esError
                    ? esquema.onErrorContainer
                    : esquema.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
