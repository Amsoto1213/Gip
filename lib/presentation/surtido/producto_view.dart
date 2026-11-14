import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/presentation/surtido/producto_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Producto (CUS-18, mockups `mProducto` y `wProducto`): el mismo
/// formulario crea y edita. Lleva el campo "Código interno", que no está en el
/// mockup (DI-14). Las secciones de códigos y etiquetas llegan con CUS-17 y la
/// iteración 4.
class ProductoView extends StatefulWidget {
  const ProductoView({super.key});

  @override
  State<ProductoView> createState() => _ProductoViewState();
}

class _ProductoViewState extends State<ProductoView> {
  final _codigo = TextEditingController();
  final _nombre = TextEditingController();
  final _precioVenta = TextEditingController();
  final _precioCompra = TextEditingController();
  UnidadMedida _unidad = UnidadMedida.unidad;

  @override
  void initState() {
    super.initState();
    final producto = context.read<ProductoViewModel>().producto;
    if (producto != null) _cargar(producto);
  }

  void _cargar(Producto producto) {
    _codigo.text = producto.getCodigo();
    _nombre.text = producto.getNombre();
    _unidad = producto.getUnidadMedida();
    _precioVenta.text = _mostrarPrecio(producto.getPrecioVenta().toString());
    final compra = producto.getPrecioCompra();
    _precioCompra.text = compra == null
        ? ''
        : _mostrarPrecio(compra.toString());
  }

  /// "3500.5" → "3.500,5": miles con punto y decimales con coma.
  static String _mostrarPrecio(String valor) {
    final partes = valor.split('.');
    final entero = partes.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return partes.length > 1 ? '$entero,${partes[1]}' : entero;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _precioVenta.dispose();
    _precioCompra.dispose();
    super.dispose();
  }

  void _guardar() {
    FocusScope.of(context).unfocus();
    context.read<ProductoViewModel>().guardar(
      codigo: _codigo.text,
      nombre: _nombre.text,
      unidad: _unidad,
      precioVenta: _precioVenta.text,
      precioCompra: _precioCompra.text,
    );
  }

  void _volver() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(rutaPrincipalSurtido);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductoViewModel>();
    final ancho = MediaQuery.sizeOf(context).width >= 720;
    final botonGuardar = FilledButton.icon(
      onPressed: vm.guardando ? null : _guardar,
      icon: vm.guardando
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : const Icon(Icons.check),
      label: const Text('Guardar producto'),
    );

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                ancho ? 32 : 20,
                16,
                ancho ? 32 : 20,
                24,
              ),
              children: [
                _Encabezado(esNuevo: vm.esNuevo, onVolver: _volver),
                const SizedBox(height: 8),
                Text(
                  'El mismo formulario sirve para editar un producto.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _formulario(vm, ancho),
                if (vm.error != null) ...[
                  const SizedBox(height: 16),
                  _Mensaje(texto: vm.error!, esError: true),
                ],
                if (vm.aviso != null) ...[
                  const SizedBox(height: 16),
                  _Mensaje(texto: vm.aviso!, esError: false),
                ],
                const SizedBox(height: 24),
                if (ancho)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _volver,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(120, 56),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(width: 260, child: botonGuardar),
                    ],
                  )
                else
                  botonGuardar,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulario(ProductoViewModel vm, bool ancho) {
    final habilitado = !vm.guardando;
    final tema = Theme.of(context);
    final precios = [
      TextField(
        key: const Key('producto_precio_venta'),
        controller: _precioVenta,
        enabled: habilitado,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Precio de venta',
          prefixText: r'$ ',
        ),
      ),
      TextField(
        key: const Key('producto_precio_compra'),
        controller: _precioCompra,
        enabled: habilitado,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Costo (opcional)',
          prefixText: r'$ ',
          helperText: 'Sin costo, la ganancia sale incompleta.',
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('producto_codigo'),
          controller: _codigo,
          // El código interno no se edita (DA-48, DA-50, DI-14).
          enabled: habilitado && vm.esNuevo,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Código interno',
            helperText: vm.esNuevo ? null : 'El código interno no se cambia',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('producto_nombre'),
          controller: _nombre,
          enabled: habilitado,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        const SizedBox(height: 20),
        Text('Se vende por', style: tema.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<UnidadMedida>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(minimumSize: const Size(0, 48)),
          segments: const [
            ButtonSegment(value: UnidadMedida.unidad, label: Text('Unidad')),
            ButtonSegment(value: UnidadMedida.kilogramo, label: Text('Kilo')),
            ButtonSegment(value: UnidadMedida.libra, label: Text('Libra')),
          ],
          selected: {_unidad},
          onSelectionChanged: habilitado
              ? (seleccion) => setState(() => _unidad = seleccion.single)
              : null,
        ),
        const SizedBox(height: 20),
        if (ancho)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: precios[0]),
              const SizedBox(width: 16),
              Expanded(child: precios[1]),
            ],
          )
        else ...[
          precios[0],
          const SizedBox(height: 16),
          precios[1],
        ],
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.esNuevo, required this.onVolver});

  final bool esNuevo;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: onVolver,
          tooltip: 'Volver',
          iconSize: 28,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SURTIDO',
                style: tema.textTheme.labelMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  esNuevo ? 'Producto nuevo' : 'Editar producto',
                  style: tema.textTheme.headlineLarge,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.texto, required this.esError});

  final String texto;
  final bool esError;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final fondo = esError ? esquema.errorContainer : esquema.primaryContainer;
    final color = esError ? esquema.error : esquema.onPrimaryContainer;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              esError ? Icons.warning_amber_rounded : Icons.check_circle,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
