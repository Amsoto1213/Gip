import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/icono_paquete.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';

/// Piezas propias de las pantallas que mueven el surtido de un producto:
/// Entrada de mercancía (CUS-01) y Pérdida o devolución (CUS-03), con el
/// patrón de `docs/ui/rediseno/perdida-web.html`. Cada pantalla pasa su
/// `prefijoClave` ("entrada", "perdida") para que sus claves de prueba no
/// choquen.

/// Cantidad como texto: sin miles y con coma decimal (2,5).
String mostrarCantidad(Decimal cantidad) =>
    cantidad.toString().replaceAll('.', ',');

/// Unidad abreviada para el resumen: "und", "kg", "lb".
String unidadCorta(UnidadMedida unidad) => switch (unidad) {
  UnidadMedida.unidad => 'und',
  UnidadMedida.kilogramo => 'kg',
  UnidadMedida.libra => 'lb',
};

/// Nombre de la unidad como lo ve el tendero.
String nombreUnidad(UnidadMedida unidad) => switch (unidad) {
  UnidadMedida.unidad => 'Unidad',
  UnidadMedida.kilogramo => 'Kilogramo',
  UnidadMedida.libra => 'Libra',
};

/// Nombre del motivo de una pérdida como lo ve el tendero (CUS-03, CUS-25).
String nombreMotivo(MotivoMerma motivo) => switch (motivo) {
  MotivoMerma.vencido => 'Vencido',
  MotivoMerma.danado => 'Dañado',
  MotivoMerma.devueltoProveedor => 'Devuelto al proveedor',
  MotivoMerma.otro => 'Otro',
};

/// Etiqueta en mayúsculas de cada panel ("PRODUCTO", "¿CUÁNTAS SALEN…?").
class EtiquetaPanel extends StatelessWidget {
  const EtiquetaPanel(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Text(
      texto.toUpperCase(),
      style: tema.textTheme.labelMedium?.copyWith(
        fontSize: 13,
        letterSpacing: 13 * 0.04,
        color: tema.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Contenido de la sección 1 "Producto y cantidad": el [producto] a la
/// izquierda y la [cantidad] a la derecha, separados por una línea; si no
/// caben, uno debajo del otro.
class PanelesProductoCantidad extends StatelessWidget {
  const PanelesProductoCantidad({
    super.key,
    required this.producto,
    required this.cantidad,
  });

  final Widget producto;
  final Widget cantidad;

  static const _relleno = EdgeInsets.symmetric(horizontal: 24, vertical: 22);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, restricciones) {
      final producto = Padding(padding: _relleno, child: this.producto);
      final cantidad = Padding(padding: _relleno, child: this.cantidad);
      if (restricciones.maxWidth >= 600) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: producto),
              const VerticalDivider(width: 1),
              Expanded(child: cantidad),
            ],
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [producto, const Divider(), cantidad],
      );
    },
  );
}

/// Panel del producto elegido: caja con el ícono de paquete, nombre, "código ·
/// unidad", la píldora [existencia] ("Hay 14") si se conoce, y el botón que
/// abre Buscar producto (CUS-06) en modo seleccionar.
class PanelProducto extends StatelessWidget {
  const PanelProducto({
    super.key,
    required this.prefijoClave,
    required this.producto,
    required this.textoSinProducto,
    required this.habilitado,
    required this.onElegir,
    this.existencia,
  });

  final String prefijoClave;
  final Producto? producto;

  /// Primera línea sin producto ("¿Qué producto sale?").
  final String textoSinProducto;
  final String? existencia;
  final bool habilitado;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final producto = this.producto;
    final existencia = this.existencia;
    final detalle = tema.textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EtiquetaPanel('Producto'),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: esquema.primaryContainer,
                borderRadius: BorderRadius.circular(FormaGip.radioCajaIcono),
              ),
              child: IconoPaquete(tamano: 28, color: esquema.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto?.getNombre() ?? textoSinProducto,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        producto == null
                            ? 'Búsquelo por el nombre'
                            : '${producto.getCodigo()} · '
                                  '${nombreUnidad(producto.getUnidadMedida())}',
                        style: detalle,
                      ),
                      if (producto != null && existencia != null)
                        Container(
                          key: Key('${prefijoClave}_existencia'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: esquema.primaryContainer,
                            borderRadius: BorderRadius.circular(
                              FormaGip.radioChip,
                            ),
                          ),
                          child: Text(
                            existencia,
                            style: detalle?.copyWith(
                              color: esquema.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BotonSecundario(
          key: Key('${prefijoClave}_elegir_producto'),
          texto: producto == null ? 'Elegir producto' : 'Cambiar producto',
          icono: Icons.swap_horiz,
          onPressed: habilitado ? onElegir : null,
        ),
      ],
    );
  }
}

/// Cantidad grande (Archivo 800, 38 px) entre los botones − y + de fondo
/// `pasoFondo`, con la [unidad] al lado del número. La caja del número toma
/// el borde `primario` y el halo al tener el foco.
class SelectorCantidad extends StatefulWidget {
  const SelectorCantidad({
    super.key,
    required this.prefijoClave,
    required this.controlador,
    required this.habilitado,
    required this.onCambio,
    required this.onSumar,
    this.unidad,
    this.decimales = true,
  });

  final String prefijoClave;
  final TextEditingController controlador;
  final bool habilitado;
  final ValueChanged<String> onCambio;
  final ValueChanged<int> onSumar;

  /// "und", "kg", "lb"; nula si todavía no hay producto.
  final String? unidad;

  /// Si el teclado ofrece la coma decimal (kilos y libras).
  final bool decimales;

  @override
  State<SelectorCantidad> createState() => _SelectorCantidadState();
}

class _SelectorCantidadState extends State<SelectorCantidad> {
  final _foco = FocusNode();
  bool _enfocado = false;

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final extra = tema.extension<ColoresExtraGip>()!;
    final bordes = BorderRadius.circular(18);
    final estilo = ButtonStyle(
      fixedSize: const WidgetStatePropertyAll(Size.square(60)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: bordes),
      ),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith(
        (estados) =>
            estados.contains(WidgetState.hovered) ||
                estados.contains(WidgetState.focused) ||
                estados.contains(WidgetState.pressed)
            ? extra.pasoFondoActivo
            : extra.pasoFondo,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.disabled)
            ? esquema.onSurfaceVariant.withValues(alpha: 0.5)
            : esquema.onSurface,
      ),
    );
    Widget paso(int valor, IconData icono, String ayuda) => IconButton(
      key: Key(
        '${widget.prefijoClave}_cantidad_${valor > 0 ? 'mas' : 'menos'}',
      ),
      onPressed: widget.habilitado ? () => widget.onSumar(valor) : null,
      tooltip: ayuda,
      iconSize: 24,
      style: estilo,
      icon: Icon(icono),
    );
    final unidad = widget.unidad;
    return Row(
      children: [
        paso(-1, Icons.remove, 'Quitar una'),
        const SizedBox(width: 12),
        Expanded(
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onFocusChange: (enfocado) => setState(() => _enfocado = enfocado),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: esquema.surface,
                borderRadius: bordes,
                border: Border.all(
                  color: _enfocado ? esquema.primary : esquema.outline,
                  width: FormaGip.grosorBordeCampo,
                ),
                boxShadow: _enfocado ? FormaGip.haloFoco : null,
              ),
              // El número y la unidad van juntos y centrados: el campo mide
              // lo que su texto, y tocar cualquier parte de la caja lo enfoca.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.habilitado ? _foco.requestFocus : null,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controlador,
                  builder: (context, valor, _) {
                    final estiloNumero = tema.textTheme.headlineLarge
                        ?.copyWith(fontSize: 38, height: 1.1)
                        .cifrasTabulares;
                    final medida = TextPainter(
                      text: TextSpan(
                        text: valor.text.isEmpty ? '0' : valor.text,
                        style: estiloNumero,
                      ),
                      textDirection: TextDirection.ltr,
                      textScaler: MediaQuery.textScalerOf(context),
                      maxLines: 1,
                    )..layout();
                    final anchoTexto = medida.width;
                    medida.dispose();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // Flexible: si no cabe, el campo se encoge y la
                        // unidad sigue a la vista.
                        Flexible(
                          child: SizedBox(
                            width: anchoTexto + 8,
                            child: TextField(
                              key: Key('${widget.prefijoClave}_cantidad'),
                              controller: widget.controlador,
                              focusNode: _foco,
                              enabled: widget.habilitado,
                              onChanged: widget.onCambio,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: widget.decimales,
                              ),
                              style: estiloNumero,
                              decoration: const InputDecoration(
                                hintText: '0',
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),
                        ),
                        if (unidad != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            unidad,
                            style: tema.textTheme.bodyLarge?.copyWith(
                              color: esquema.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        paso(1, Icons.add, 'Agregar una'),
      ],
    );
  }
}

/// Atajo en forma de píldora bajo la cantidad ("Todas (14)").
class AtajoCantidad extends StatelessWidget {
  const AtajoCantidad({
    super.key,
    required this.texto,
    required this.onPressed,
  });

  final String texto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return OutlinedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 38)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        textStyle: WidgetStatePropertyAll(
          tema.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.hovered)
              ? esquema.primary
              : esquema.onSurface,
        ),
        side: WidgetStateProperty.resolveWith(
          (estados) => BorderSide(
            color: estados.contains(WidgetState.hovered)
                ? esquema.primary
                : esquema.outlineVariant,
            width: FormaGip.grosorBordeCampo,
          ),
        ),
      ),
      child: Text(texto),
    );
  }
}

/// Fila etiqueta / valor de la barra inferior del teléfono. Con [destacada]
/// el valor va en Archivo 800 de 23 px ("Quedará en", "Total de la compra").
class FilaResumen extends StatelessWidget {
  const FilaResumen(
    this.etiqueta,
    this.valor, {
    super.key,
    this.destacada = false,
  });

  final String etiqueta;
  final String valor;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final estiloEtiqueta = destacada
        ? textos.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : textos.bodyLarge;
    final estiloValor = destacada
        ? textos.headlineMedium
        : textos.bodyLarge?.copyWith(fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: estiloEtiqueta)),
          Text(valor, style: estiloValor?.cifrasTabulares),
        ],
      ),
    );
  }
}

/// Barra fija abajo en el teléfono con los mensajes, el total o el saldo y el
/// botón principal.
class BarraInferiorMovimiento extends StatelessWidget {
  const BarraInferiorMovimiento({
    super.key,
    required this.margen,
    required this.hijos,
  });

  final double margen;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        border: Border(top: BorderSide(color: tema.colorScheme.outlineVariant)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(margen, 8, margen, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: hijos,
        ),
      ),
    );
  }
}

/// Error o aviso del último intento, junto al botón para que se vea siempre
/// (en el teléfono, el formulario puede quedar debajo del teclado).
class MensajesMovimiento extends StatelessWidget {
  const MensajesMovimiento({
    super.key,
    required this.error,
    required this.aviso,
  });

  final String? error;
  final String? aviso;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    final aviso = this.aviso;
    if (error == null && aviso == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: error != null
          ? _Mensaje(texto: error, esError: true)
          : _Mensaje(texto: aviso!, esError: false),
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

/// Columnas de una pantalla de movimiento en la web: el formulario a la
/// izquierda y el resumen a la derecha (340–420 px). Si no caben, el resumen
/// va debajo.
class ColumnasMovimiento extends StatelessWidget {
  const ColumnasMovimiento({
    super.key,
    required this.formulario,
    required this.resumen,
  });

  final Widget formulario;
  final Widget resumen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, restricciones) {
      final ancho = restricciones.maxWidth;
      if (ancho < 520 + 24 + 340) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [formulario, const SizedBox(height: 24), resumen],
        );
      }
      final anchoResumen = (ancho * 0.34).clamp(340.0, 420.0);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: formulario),
          const SizedBox(width: 24),
          SizedBox(width: anchoResumen, child: resumen),
        ],
      );
    },
  );
}
