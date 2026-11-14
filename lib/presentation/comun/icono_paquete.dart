import 'package:flutter/material.dart';

/// Ícono de paquete de trazo (estilo Lucide, `docs/ui/tokens.md`): la caja en
/// perspectiva de los mockups de Surtido. La fuente de Material no trae uno
/// igual (`inventory_2` es una caja de archivo). Toma el color de [color] o
/// del `IconTheme`.
class IconoPaquete extends StatelessWidget {
  const IconoPaquete({super.key, this.tamano = 24, this.color});

  final double tamano;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    excludeSemantics: true,
    child: CustomPaint(
      size: Size.square(tamano),
      painter: _PintorPaquete(color ?? IconTheme.of(context).color!),
    ),
  );
}

class _PintorPaquete extends CustomPainter {
  _PintorPaquete(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Trazado sobre una cuadrícula de 24 x 24, como los íconos Lucide.
    final escala = size.width / 24;
    canvas.scale(escala);
    final trazo = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final contorno = Path()
      ..moveTo(12, 2)
      ..lineTo(21, 7)
      ..lineTo(21, 17)
      ..lineTo(12, 22)
      ..lineTo(3, 17)
      ..lineTo(3, 7)
      ..close();
    final caras = Path()
      ..moveTo(3, 7)
      ..lineTo(12, 12)
      ..lineTo(21, 7)
      ..moveTo(12, 12)
      ..lineTo(12, 22)
      ..moveTo(7.5, 4.5)
      ..lineTo(16.5, 9.5);
    canvas
      ..drawPath(contorno, trazo)
      ..drawPath(caras, trazo);
  }

  @override
  bool shouldRepaint(_PintorPaquete viejo) => viejo.color != color;
}
