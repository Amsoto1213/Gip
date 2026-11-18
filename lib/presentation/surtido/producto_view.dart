import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/contador_entero.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/leer_codigo.dart';
import 'package:gip/presentation/comun/mensaje_resultado.dart';
import 'package:gip/presentation/comun/seccion_numerada.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/surtido/producto_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Producto (CUS-18, mockups `mProducto` y `wProducto`, con los
/// componentes del rediseño): el mismo
/// formulario crea y edita. Lleva el campo "Código interno", que no está en el
/// mockup (DI-14). La sección "Códigos del producto" asocia códigos de barras
/// o QR (CUS-17, DI-34); sin el botón de quitar (CUS-22). Con el producto
/// guardado, el panel "Etiquetas QR" imprime sus etiquetas (DI-35): al lado en
/// la web y debajo de los códigos en el móvil.
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

  Future<void> _asociarCodigo() async {
    FocusScope.of(context).unfocus();
    final vm = context.read<ProductoViewModel>();
    final valor = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogoCodigo(),
    );
    if (valor != null && mounted) await vm.asociarCodigo(valor);
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
            constraints: BoxConstraints(
              maxWidth: web && !vm.esNuevo ? 1180 : 968,
            ),
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
                if (web && !vm.esNuevo)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _formulario(vm, web, botonGuardar)),
                      const SizedBox(width: 24),
                      SizedBox(width: 300, child: _PanelEtiquetas(vm: vm)),
                    ],
                  )
                else
                  _formulario(vm, web, botonGuardar),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulario(ProductoViewModel vm, bool web, Widget botonGuardar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _seccionDatos(vm, web),
        const SizedBox(height: 18),
        _seccionPrecios(vm, web),
        const SizedBox(height: 18),
        _SeccionCodigos(vm: vm, onAsociar: _asociarCodigo),
        if (!web && !vm.esNuevo) ...[
          const SizedBox(height: 18),
          _PanelEtiquetas(vm: vm),
        ],
        if (vm.error != null) ...[
          const SizedBox(height: 16),
          MensajeResultado(texto: vm.error!, esError: true),
        ],
        if (vm.aviso != null) ...[
          const SizedBox(height: 16),
          MensajeResultado(texto: vm.aviso!, esError: false),
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
      ayuda: 'Cada entrada de mercancía lo actualiza con su costo.',
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

/// Panel "Etiquetas QR" (mockup `wProducto`): vista previa de la etiqueta,
/// copias e "Imprimir etiquetas". Solo con el producto guardado. La vista
/// previa no dibuja el QR real: el producto puede no tener todavía su código
/// QR, que se crea al imprimir (DI-35).
class _PanelEtiquetas extends StatelessWidget {
  const _PanelEtiquetas({required this.vm});

  final ProductoViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final producto = vm.producto!;
    final ocupado = vm.imprimiendo || vm.guardando;
    return TarjetaGip(
      key: const Key('producto_panel_etiquetas'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Etiquetas QR', style: tema.textTheme.titleLarge),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FormaGip.radioCampo),
              border: Border.all(color: esquema.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.qr_code_2, size: 64, color: esquema.onSurface),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.getNombre(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.titleSmall,
                      ),
                      Text(
                        '\$ ${mostrarPrecio(producto.getPrecioVenta())}',
                        style: tema.textTheme.titleLarge?.cifrasTabulares,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Copias', style: tema.textTheme.labelMedium),
          const SizedBox(height: 8),
          ContadorEntero(
            valor: vm.copias,
            maximo: ProductoViewModel.copiasMaximas,
            etiquetaMenos: 'Una copia menos',
            etiquetaMas: 'Una copia más',
            onCambio: ocupado ? null : vm.cambiarCopias,
          ),
          const SizedBox(height: 16),
          BotonSecundario(
            key: const Key('producto_imprimir_etiquetas'),
            texto: 'Imprimir etiquetas',
            icono: Icons.print_outlined,
            expandido: true,
            onPressed: ocupado ? null : vm.imprimirEtiquetas,
          ),
        ],
      ),
    );
  }
}

/// Sección 3 "Códigos del producto" (mockup `mProducto`): los códigos ya
/// asociados, el pendiente de un producto nuevo y "Asociar código".
class _SeccionCodigos extends StatelessWidget {
  const _SeccionCodigos({required this.vm, required this.onAsociar});

  final ProductoViewModel vm;
  final VoidCallback onAsociar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final secundario = tema.textTheme.bodyMedium?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
    );
    final pendiente = vm.codigoPendiente;
    final codigos = vm.codigos;
    return SeccionNumerada(
      numero: 3,
      titulo: 'Códigos del producto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (codigos.isEmpty && pendiente == null)
            Text(
              'Asocie el código de barras o QR del empaque para encontrarlo '
              'con el lector.',
              style: secundario,
            ),
          for (final c in codigos)
            _FilaCodigo(
              key: Key('producto_codigo_${c.getValor()}'),
              valor: c.getValor(),
              detalle: nombreFormato(c.getFormato()),
              esQr: c.getFormato() == FormatoCodigo.qr,
            ),
          if (pendiente != null)
            _FilaCodigo(
              key: const Key('producto_codigo_pendiente'),
              valor: pendiente,
              detalle: 'Se asociará al guardar el producto',
              esQr: false,
              onDescartar: vm.guardando ? null : vm.descartarCodigoPendiente,
            ),
          const SizedBox(height: 12),
          BotonSecundario(
            key: const Key('producto_asociar_codigo'),
            texto: codigos.isEmpty && pendiente == null
                ? 'Asociar código'
                : 'Asociar otro código',
            icono: Icons.qr_code_scanner,
            expandido: true,
            onPressed: vm.guardando ? null : onAsociar,
          ),
        ],
      ),
    );
  }
}

class _FilaCodigo extends StatelessWidget {
  const _FilaCodigo({
    super.key,
    required this.valor,
    required this.detalle,
    required this.esQr,
    this.onDescartar,
  });

  final String valor;
  final String detalle;
  final bool esQr;

  /// Solo para el código pendiente, que todavía no se ha guardado.
  final VoidCallback? onDescartar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        decoration: BoxDecoration(
          color: esquema.surface,
          borderRadius: BorderRadius.circular(FormaGip.radioCampo),
          border: Border.all(color: esquema.outline),
        ),
        child: Row(
          children: [
            Icon(
              esQr ? Icons.qr_code_2 : Icons.qr_code_scanner,
              color: esquema.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valor,
                    style: tema.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700)
                        .cifrasTabulares,
                  ),
                  Text(
                    detalle,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (onDescartar != null)
              IconButton(
                key: const Key('producto_descartar_codigo'),
                tooltip: 'No asociar este código',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: onDescartar,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo "Asociar código": el lector 2D en modo teclado escribe en el campo
/// y oprime Enter; también se puede escribir a mano o, en la app Android,
/// leer con la cámara. Devuelve el texto, o null si se cancela.
class _DialogoCodigo extends StatefulWidget {
  const _DialogoCodigo();

  @override
  State<_DialogoCodigo> createState() => _DialogoCodigoState();
}

class _DialogoCodigoState extends State<_DialogoCodigo> {
  final _valor = TextEditingController();
  final _foco = FocusNode();
  String? _aviso;

  @override
  void initState() {
    super.initState();
    // Listo para que el lector 2D escriba sin tocar el campo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _foco.requestFocus();
    });
  }

  @override
  void dispose() {
    _valor.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _aceptar() => Navigator.of(context).pop(_valor.text);

  Future<void> _leerConCamara() async {
    final resultado = await leerCodigoConCamara(context);
    if (!mounted) return;
    switch (resultado) {
      case null:
        return;
      case LecturaFallida():
        setState(() => _aviso = 'No se pudo usar la cámara. Escriba el código');
      case LecturaLeida(:final texto):
        Navigator.of(context).pop(texto);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asociar código'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoGip(
              etiqueta: 'Código de barras o QR',
              controlador: _valor,
              campoKey: const Key('producto_valor_codigo'),
              focusNode: _foco,
              icono: Icons.qr_code_scanner,
              ayuda: 'Dispare el lector o escriba el código',
              error: _aviso,
              accionTeclado: TextInputAction.done,
              onSubmitted: (_) => _aceptar(),
            ),
            if (camaraDisponible) ...[
              const SizedBox(height: 12),
              BotonSecundario(
                key: const Key('producto_codigo_camara'),
                texto: 'Leer con la cámara',
                icono: Icons.photo_camera_outlined,
                expandido: true,
                onPressed: _leerConCamara,
              ),
            ],
          ],
        ),
      ),
      actions: [
        BotonSecundario(
          texto: 'Cancelar',
          sinBorde: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        BotonPrimario(
          key: const Key('producto_confirmar_codigo'),
          texto: 'Asociar',
          compacto: true,
          onPressed: _aceptar,
        ),
      ],
    );
  }
}
