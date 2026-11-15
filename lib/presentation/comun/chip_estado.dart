import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Estado de existencia de un producto.
enum EstadoExistencia { poco, agotado }

/// Píldora de estado: "Poco" en los colores de alerta y "Agotado" en los de
/// error. Solo marca estados; nunca es una acción.
class ChipEstado extends StatelessWidget {
  const ChipEstado(this.estado, {super.key});

  final EstadoExistencia estado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final (texto, fondo, color) = switch (estado) {
      EstadoExistencia.poco => ('Poco', extra.alertaFondo, extra.alertaTexto),
      EstadoExistencia.agotado => (
        'Agotado',
        tema.colorScheme.errorContainer,
        tema.colorScheme.error,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(FormaGip.radioChip),
      ),
      child: Text(
        texto,
        style: tema.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
