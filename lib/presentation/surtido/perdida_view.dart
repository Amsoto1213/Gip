import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/surtido/perdida_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:gip/presentation/surtido/widgets_movimiento.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Pérdida o devolución (CUS-03, mockups `mPerdida` y `wPerdida`).
///
/// El producto se elige en Buscar producto (CUS-06) en modo seleccionar; si la
/// pantalla abre sin producto, la búsqueda se abre sola. El motivo se elige de
/// la lista cerrada y sin él no se puede confirmar (IE-03).
class PerdidaView extends StatefulWidget {
  const PerdidaView({super.key});

  @override
  State<PerdidaView> createState() => _PerdidaViewState();
}

class _PerdidaViewState extends State<PerdidaView> {
  final _cantidad = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (context.read<PerdidaViewModel>().producto == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _elegirProducto();
      });
    }
  }

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  Future<void> _elegirProducto() async {
    final vm = context.read<PerdidaViewModel>();
    final producto = await elegirProducto(context);
    if (producto != null) await vm.elegirProducto(producto);
  }

  void _sumar(int paso) {
    final cantidad = context.read<PerdidaViewModel>().sumarCantidad(
      Decimal.fromInt(paso),
    );
    _cantidad.text = mostrarCantidad(cantidad);
  }

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    final registrada = await context.read<PerdidaViewModel>().registrar();
    if (registrada) _cantidad.clear();
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
    final vm = context.watch<PerdidaViewModel>();
    final ancho = MediaQuery.sizeOf(context).width >= 720;
    final margen = ancho ? 32.0 : 20.0;
    final boton = BotonRegistrarMovimiento(
      prefijoClave: 'perdida',
      texto: 'Registrar pérdida',
      registrando: vm.registrando,
      onPressed: vm.puedeConfirmar ? _registrar : null,
    );
    final encabezado = EncabezadoSurtido(
      titulo: ancho
          ? 'Pérdida o devolución al proveedor'
          : 'Pérdida o devolución',
      onVolver: _volver,
    );
    final formulario = _formulario(vm, ancho);

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ancho ? 1180 : 880),
            child: ancho
                ? ListView(
                    padding: EdgeInsets.fromLTRB(margen, 16, margen, 24),
                    children: [
                      encabezado,
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: formulario,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: _Resumen(vm: vm, boton: boton),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(margen, 16, margen, 24),
                          children: [
                            encabezado,
                            const SizedBox(height: 16),
                            formulario,
                          ],
                        ),
                      ),
                      BarraInferiorMovimiento(
                        margen: margen,
                        hijos: [
                          MensajesMovimiento(error: vm.error, aviso: vm.aviso),
                          FilaResumen(
                            'Existencia quedará en',
                            _quedaraEnLargo(vm),
                          ),
                          const SizedBox(height: 8),
                          boton,
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _formulario(PerdidaViewModel vm, bool ancho) {
    final tema = Theme.of(context);
    final habilitado = !vm.registrando;
    final etiqueta = tema.textTheme.titleSmall?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
    );
    final producto = vm.producto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ancho) ...[
          Text('Producto', style: etiqueta),
          const SizedBox(height: 8),
        ],
        TarjetaProductoMovimiento(
          prefijoClave: 'perdida',
          producto: producto,
          detalle: producto == null ? '' : _detalleProducto(vm, producto),
          textoSinProducto: '¿Qué producto sale?',
          habilitado: habilitado,
          onElegir: _elegirProducto,
        ),
        const SizedBox(height: 20),
        Text('¿Cuántas salen del surtido?', style: etiqueta),
        const SizedBox(height: 8),
        SelectorCantidad(
          prefijoClave: 'perdida',
          controlador: _cantidad,
          habilitado: habilitado,
          decimales: vm.admiteDecimales,
          onCambio: vm.cambiarCantidad,
          onSumar: _sumar,
        ),
        const SizedBox(height: 20),
        Text('Motivo (obligatorio)', style: etiqueta),
        const SizedBox(height: 8),
        _SelectorMotivo(
          seleccionado: vm.motivo,
          habilitado: habilitado,
          onElegir: (motivo) {
            // Cierra el teclado de la cantidad al elegir el motivo.
            FocusScope.of(context).unfocus();
            vm.elegirMotivo(motivo);
          },
        ),
        const SizedBox(height: 16),
        const _NotaMotivo(),
      ],
    );
  }
}

/// Nombre del motivo como lo ve el tendero.
String _nombreMotivo(MotivoMerma motivo) => switch (motivo) {
  MotivoMerma.vencido => 'Vencido',
  MotivoMerma.danado => 'Dañado',
  MotivoMerma.devueltoProveedor => 'Devuelto al proveedor',
  MotivoMerma.otro => 'Otro',
};

String _nombreUnidad(UnidadMedida unidad) => switch (unidad) {
  UnidadMedida.unidad => 'Unidad',
  UnidadMedida.kilogramo => 'Kilogramo',
  UnidadMedida.libra => 'Libra',
};

/// "Hay 14 · Unidad"; sin la existencia todavía, solo la unidad.
String _detalleProducto(PerdidaViewModel vm, Producto producto) {
  final unidad = _nombreUnidad(producto.getUnidadMedida());
  final existencia = vm.existencia;
  return existencia == null
      ? unidad
      : 'Hay ${mostrarCantidad(existencia)} · $unidad';
}

/// "12 unidades", "1 unidad", "2,5 kg".
String _cantidadLarga(Decimal cantidad, UnidadMedida unidad) {
  final texto = mostrarCantidad(cantidad);
  return switch (unidad) {
    UnidadMedida.unidad when cantidad == Decimal.one => '$texto unidad',
    UnidadMedida.unidad => '$texto unidades',
    _ => '$texto ${unidadCorta(unidad)}',
  };
}

String _quedaraEnLargo(PerdidaViewModel vm) {
  final quedara = vm.quedaraEn;
  final producto = vm.producto;
  if (quedara == null || producto == null) return '—';
  return _cantidadLarga(quedara, producto.getUnidadMedida());
}

/// Lista cerrada de motivos en tarjetas de opción única (IE-03 b).
class _SelectorMotivo extends StatelessWidget {
  const _SelectorMotivo({
    required this.seleccionado,
    required this.habilitado,
    required this.onElegir,
  });

  final MotivoMerma? seleccionado;
  final bool habilitado;
  final ValueChanged<MotivoMerma> onElegir;

  static const _separacion = 12.0;

  /// Una fila de 4 (wPerdida) si en cada opción cabe la palabra más larga de
  /// los motivos; si no, 2 x 2 (mPerdida); en una pantalla muy angosta o con
  /// letra muy grande, una por fila. Así ninguna palabra se corta
  /// ("Devuelto al / proveedor").
  @override
  Widget build(BuildContext context) {
    final estilo = _OpcionMotivo.estiloTexto(context);
    final escala = MediaQuery.textScalerOf(context);
    var palabraMasLarga = 0.0;
    for (final motivo in MotivoMerma.values) {
      for (final palabra in _nombreMotivo(motivo).split(' ')) {
        final medida = TextPainter(
          text: TextSpan(text: palabra, style: estilo),
          textDirection: TextDirection.ltr,
          textScaler: escala,
          maxLines: 1,
        )..layout();
        if (medida.width > palabraMasLarga) palabraMasLarga = medida.width;
        medida.dispose();
      }
    }
    final anchoNecesario = _OpcionMotivo.anchoFijo + palabraMasLarga.ceil() + 1;
    return LayoutBuilder(
      builder: (context, restricciones) {
        double anchoCon(int columnas) =>
            (restricciones.maxWidth - (columnas - 1) * _separacion) / columnas;
        final columnas = anchoCon(4) >= anchoNecesario
            ? 4
            : anchoCon(2) >= anchoNecesario
            ? 2
            : 1;
        return _cuadricula(columnas);
      },
    );
  }

  Widget _cuadricula(int columnas) {
    const separacion = _separacion;
    final filas = <Widget>[];
    const motivos = MotivoMerma.values;
    for (var i = 0; i < motivos.length; i += columnas) {
      if (i > 0) filas.add(const SizedBox(height: separacion));
      filas.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = i; j < i + columnas && j < motivos.length; j++) ...[
                if (j > i) const SizedBox(width: separacion),
                Expanded(
                  child: _OpcionMotivo(
                    motivo: motivos[j],
                    seleccionada: motivos[j] == seleccionado,
                    habilitado: habilitado,
                    onElegir: onElegir,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Semantics(
      label: 'Motivo (obligatorio)',
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: filas,
      ),
    );
  }
}

class _OpcionMotivo extends StatelessWidget {
  const _OpcionMotivo({
    required this.motivo,
    required this.seleccionada,
    required this.habilitado,
    required this.onElegir,
  });

  final MotivoMerma motivo;
  final bool seleccionada;
  final bool habilitado;
  final ValueChanged<MotivoMerma> onElegir;

  static const _relleno = 12.0;
  static const _icono = 20.0;
  static const _espacio = 10.0;

  /// Ancho de la opción sin contar el texto: relleno, radio y espacio.
  static const anchoFijo = 2 * _relleno + _icono + _espacio;

  /// Texto de la opción: Inter 15 en negrita, como en los mockups.
  static TextStyle? estiloTexto(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium
          ?.copyWith(fontWeight: FontWeight.w700, height: 1.2);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: seleccionada ? esquema.primary : esquema.outlineVariant,
        width: seleccionada ? 2 : 1,
      ),
    );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: seleccionada,
      button: true,
      child: Material(
        key: Key('perdida_motivo_${motivo.name}'),
        color: seleccionada ? esquema.primaryContainer : esquema.surface,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: habilitado ? () => onElegir(motivo) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _relleno,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Icon(
                    seleccionada
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: _icono,
                    color: seleccionada
                        ? esquema.primary
                        : esquema.onSurfaceVariant,
                  ),
                  const SizedBox(width: _espacio),
                  Expanded(
                    child: Text(
                      _nombreMotivo(motivo),
                      style: estiloTexto(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nota informativa del mockup bajo los motivos.
class _NotaMotivo extends StatelessWidget {
  const _NotaMotivo();

  @override
  Widget build(BuildContext context) {
    final extra = Theme.of(context).extension<ColoresExtraGip>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: extra.info,
        border: Border.all(color: extra.infoTexto.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: extra.infoTexto),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No se puede guardar sin motivo. El motivo aparece en el '
              'reporte de pérdidas del mes.',
              style: TextStyle(color: extra.infoTexto),
            ),
          ),
        ],
      ),
    );
  }
}

/// Columna derecha en escritorio (`wPerdida`).
class _Resumen extends StatelessWidget {
  const _Resumen({required this.vm, required this.boton});

  final PerdidaViewModel vm;
  final Widget boton;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final producto = vm.producto;
    final unidad = producto == null
        ? ''
        : ' ${unidadCorta(producto.getUnidadMedida())}';
    final existencia = vm.existencia;
    final cantidad = vm.cantidad;
    final quedara = vm.quedaraEn;
    final motivo = vm.motivo;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resumen', style: tema.textTheme.titleLarge),
            const SizedBox(height: 12),
            FilaResumen(
              'Existencia actual',
              existencia == null
                  ? '—'
                  : '${mostrarCantidad(existencia)}$unidad',
            ),
            const Divider(),
            FilaResumen(
              'Salen',
              cantidad == null ? '—' : '− ${mostrarCantidad(cantidad)}$unidad',
            ),
            const Divider(),
            FilaResumen('Motivo', motivo == null ? '—' : _nombreMotivo(motivo)),
            const Divider(),
            FilaResumen(
              'Quedará en',
              quedara == null ? '—' : '${mostrarCantidad(quedara)}$unidad',
              destacada: true,
            ),
            const SizedBox(height: 16),
            MensajesMovimiento(error: vm.error, aviso: vm.aviso),
            boton,
          ],
        ),
      ),
    );
  }
}
