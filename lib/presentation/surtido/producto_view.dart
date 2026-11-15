import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/seccion_numerada.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/surtido/producto_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Producto (CUS-18, mockups `mProducto` y `wProducto`, con los
/// componentes del rediseño): el mismo
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
    _precioVenta.text = mostrarPrecio(producto.getPrecioVenta());
    final compra = producto.getPrecioCompra();
    _precioCompra.text = compra == null ? '' : mostrarPrecio(compra);
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
    final web = FormaGip.esWeb(context);
    final titulo = vm.esNuevo ? 'Producto nuevo' : 'Editar producto';
    final botonGuardar = BotonPrimario(
      key: const Key('producto_guardar'),
      texto: 'Guardar producto',
      icono: Icons.check,
      cargando: vm.guardando,
      onPressed: _guardar,
    );

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 968),
            child: ListView(
              padding: web
                  ? const EdgeInsets.fromLTRB(44, 32, 44, 48)
                  : const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                EncabezadoPantalla(
                  titulo: titulo,
                  miga: titulo,
                  seccion: 'Surtido',
                  contexto:
                      'El mismo formulario sirve para editar un producto.',
                  onVolver: _volver,
                ),
                SizedBox(height: web ? 24 : 16),
                _seccionDatos(vm, web),
                const SizedBox(height: 18),
                _seccionPrecios(vm, web),
                if (vm.error != null) ...[
                  const SizedBox(height: 16),
                  _Mensaje(texto: vm.error!, esError: true),
                ],
                if (vm.aviso != null) ...[
                  const SizedBox(height: 16),
                  _Mensaje(texto: vm.aviso!, esError: false),
                ],
                const SizedBox(height: 24),
                if (web)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 160,
                        child: BotonSecundario(
                          texto: 'Cancelar',
                          alto: 58,
                          expandido: true,
                          onPressed: vm.guardando ? null : _volver,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(width: 280, child: botonGuardar),
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

  Widget _seccionDatos(ProductoViewModel vm, bool web) {
    final habilitado = !vm.guardando;
    final tema = Theme.of(context);
    final codigo = CampoGip(
      etiqueta: 'Código interno',
      controlador: _codigo,
      campoKey: const Key('producto_codigo'),
      icono: Icons.tag,
      // El código interno no se edita (DA-48, DA-50, DI-14).
      habilitado: habilitado && vm.esNuevo,
      ayuda: vm.esNuevo ? null : 'El código interno no se cambia',
      accionTeclado: TextInputAction.next,
    );
    final nombre = CampoGip(
      etiqueta: 'Nombre',
      controlador: _nombre,
      campoKey: const Key('producto_nombre'),
      icono: Icons.label_outline,
      habilitado: habilitado,
      mayusculas: TextCapitalization.sentences,
      accionTeclado: TextInputAction.next,
    );
    return SeccionNumerada(
      numero: 1,
      titulo: 'Datos del producto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (web)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: codigo),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: nombre),
              ],
            )
          else ...[
            codigo,
            const SizedBox(height: 16),
            nombre,
          ],
          const SizedBox(height: 20),
          Text('Se vende por', style: tema.textTheme.labelMedium),
          const SizedBox(height: 8),
          SegmentedButton<UnidadMedida>(
            showSelectedIcon: false,
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
        ],
      ),
    );
  }

  Widget _seccionPrecios(ProductoViewModel vm, bool web) {
    final habilitado = !vm.guardando;
    final venta = CampoGip(
      etiqueta: 'Precio de venta',
      controlador: _precioVenta,
      campoKey: const Key('producto_precio_venta'),
      icono: Icons.sell_outlined,
      prefijo: r'$ ',
      habilitado: habilitado,
      tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
    );
    final costo = CampoGip(
      etiqueta: 'Costo (opcional)',
      controlador: _precioCompra,
      campoKey: const Key('producto_precio_compra'),
      icono: Icons.payments_outlined,
      prefijo: r'$ ',
      ayuda: 'Sin costo, la ganancia sale incompleta.',
      habilitado: habilitado,
      tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
    );
    return SeccionNumerada(
      numero: 2,
      titulo: 'Precios',
      child: web
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: venta),
                const SizedBox(width: 16),
                Expanded(child: costo),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [venta, const SizedBox(height: 16), costo],
            ),
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
