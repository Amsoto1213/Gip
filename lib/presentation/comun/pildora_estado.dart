import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Tono de una [PildoraEstado].
enum TonoEstado {
  /// Verde: todo en orden ("Cuadra").
  bien,

  /// Gris: cambia sin ser un problema ("Se ajusta").
  neutro,

  /// Rojo: hay que revisar o no es válido ("Diferencia grande").
  error,

  /// Blanco con borde punteado: todavía no tiene valor ("Sin contar").
  pendiente,

  /// Azul (`info`, `infoTexto`): dato que hay que tomar con cuidado, sin ser
  /// un problema ("Provisional", alertas de surtido).
  informativo,
}

/// Píldora con el estado de una fila (13 px, peso 700, radio 999). Solo marca
/// estados; nunca es una acción. A diferencia de `ChipEstado` (existencias),
/// sirve para cualquier estado con su texto.
class PildoraEstado extends StatelessWidget {
  const PildoraEstado(this.texto, {super.key, required this.tono});

  final String texto;
  final TonoEstado tono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final extra = tema.extension<ColoresExtraGip>()!;
    final (fondo, color) = switch (tono) {
      TonoEstado.bien => (esquema.primaryContainer, esquema.onPrimaryContainer),
      TonoEstado.neutro => (
        tema.scaffoldBackgroundColor,
        esquema.onSurfaceVariant,
      ),
      TonoEstado.error => (esquema.errorContainer, esquema.error),
      TonoEstado.pendiente => (esquema.surface, esquema.onSurfaceVariant),
      TonoEstado.informativo => (extra.info, extra.infoTexto),
    };
    final pildora = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(FormaGip.radioChip),
      ),
      child: Text(
        texto,
        style: tema.textTheme.labelSmall?.copyWith(
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (tono != TonoEstado.pendiente) return pildora;
    return CustomPaint(
      foregroundPainter: _BordePunteado(esquema.outline),
      child: pildora,
    );
  }
}

/// Borde de 1 px en trazos sobre una píldora.
class _BordePunteado extends CustomPainter {
  const _BordePunteado(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pintura = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final borde = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      Radius.circular(size.height / 2),
    );
    const trazo = 4.0;
    const espacio = 3.0;
    for (final metrica in (Path()..addRRect(borde)).computeMetrics()) {
      for (var d = 0.0; d < metrica.length; d += trazo + espacio) {
        canvas.drawPath(metrica.extractPath(d, d + trazo), pintura);
      }
    }
  }

  @override
  bool shouldRepaint(_BordePunteado anterior) => anterior.color != color;
}
