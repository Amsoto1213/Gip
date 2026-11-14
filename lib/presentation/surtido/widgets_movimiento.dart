import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';

/// Piezas comunes de las pantallas que mueven el surtido de un producto:
/// Entrada de mercancía (CUS-01) y Pérdida o devolución (CUS-03). Cada pantalla
/// pasa su `prefijoClave` ("entrada", "perdida") para que sus claves de prueba
/// no choquen.

/// Cantidad como texto: sin miles y con coma decimal (2,5).
String mostrarCantidad(Decimal cantidad) =>
    cantidad.toString().replaceAll('.', ',');

/// Unidad abreviada para el resumen: "und", "kg", "lb".
String unidadCorta(UnidadMedida unidad) => switch (unidad) {
  UnidadMedida.unidad => 'und',
  UnidadMedida.kilogramo => 'kg',
  UnidadMedida.libra => 'lb',
};

/// Encabezado "SURTIDO" + título con el botón de volver.
class EncabezadoSurtido extends StatelessWidget {
  const EncabezadoSurtido({
    super.key,
    required this.titulo,
    required this.onVolver,
  });

  final String titulo;
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
                child: Text(titulo, style: tema.textTheme.headlineLarge),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarjeta con el producto elegido y el botón "Elegir"/"Cambiar", que abre
/// Buscar producto (CUS-06) en modo seleccionar.
class TarjetaProductoMovimiento extends StatelessWidget {
  const TarjetaProductoMovimiento({
    super.key,
    required this.prefijoClave,
    required this.producto,
    required this.detalle,
    required this.textoSinProducto,
    required this.habilitado,
    required this.onElegir,
  });

  final String prefijoClave;
  final Producto? producto;

  /// Segunda línea con producto ("Código X", "Hay 14 · Unidad").
  final String detalle;

  /// Primera línea sin producto ("¿Qué producto llegó?").
  final String textoSinProducto;
  final bool habilitado;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final producto = this.producto;
    final boton = OutlinedButton(
      key: Key('${prefijoClave}_elegir_producto'),
      onPressed: habilitado ? onElegir : null,
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      child: Text(producto == null ? 'Elegir' : 'Cambiar'),
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tema.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: tema.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto?.getNombre() ?? textoSinProducto,
                    style: tema.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    producto == null ? 'Búsquelo por el nombre' : detalle,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            boton,
          ],
        ),
      ),
    );
  }
}

/// Cantidad grande con botones − y + a los lados.
class SelectorCantidad extends StatelessWidget {
  const SelectorCantidad({
    super.key,
    required this.prefijoClave,
    required this.controlador,
    required this.habilitado,
    required this.onCambio,
    required this.onSumar,
    this.decimales = true,
  });

  final String prefijoClave;
  final TextEditingController controlador;
  final bool habilitado;
  final ValueChanged<String> onCambio;
  final ValueChanged<int> onSumar;

  /// Si el teclado ofrece la coma decimal (kilos y libras).
  final bool decimales;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    Widget paso(int valor, IconData icono, String ayuda) =>
        IconButton.filledTonal(
          key: Key('${prefijoClave}_cantidad_${valor > 0 ? 'mas' : 'menos'}'),
          onPressed: habilitado ? () => onSumar(valor) : null,
          tooltip: ayuda,
          iconSize: 28,
          style: IconButton.styleFrom(
            minimumSize: const Size(56, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: Icon(icono),
        );
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        border: Border.all(color: tema.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          paso(-1, Icons.remove, 'Una menos'),
          Expanded(
            child: TextField(
              key: Key('${prefijoClave}_cantidad'),
              controller: controlador,
              enabled: habilitado,
              onChanged: onCambio,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.numberWithOptions(decimal: decimales),
              style: tema.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          paso(1, Icons.add, 'Una más'),
        ],
      ),
    );
  }
}

/// Botón principal "Registrar ..." con indicador mientras guarda.
class BotonRegistrarMovimiento extends StatelessWidget {
  const BotonRegistrarMovimiento({
    super.key,
    required this.prefijoClave,
    required this.texto,
    required this.registrando,
    required this.onPressed,
  });

  final String prefijoClave;
  final String texto;
  final bool registrando;

  /// Nulo si todavía no se puede confirmar.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    key: Key('${prefijoClave}_registrar'),
    onPressed: registrando ? null : onPressed,
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
    icon: registrando
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : const Icon(Icons.check),
    label: Text(texto),
  );
}

/// Fila etiqueta / valor del resumen.
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
    final tema = Theme.of(context);
    final estilo = destacada
        ? tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : tema.textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: estilo)),
          Text(
            valor,
            style: destacada
                ? tema.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  )
                : estilo,
          ),
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
