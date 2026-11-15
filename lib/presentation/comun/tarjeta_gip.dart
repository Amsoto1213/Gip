import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Tarjeta base del rediseño: fondo `superficie`, borde 1 px `borde`, radio
/// 22 px y sombra `tarjeta` (o `elevada` para el login y el resumen). Recorta
/// su contenido a las esquinas redondeadas.
class TarjetaGip extends StatelessWidget {
  const TarjetaGip({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.elevada = false,
    this.radio = FormaGip.radioTarjeta,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Usa la sombra `elevada` en lugar de `tarjeta`.
  final bool elevada;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final bordes = BorderRadius.circular(radio);
    return Container(
      decoration: BoxDecoration(
        color: esquema.surface,
        borderRadius: bordes,
        boxShadow: elevada ? FormaGip.sombraElevada : FormaGip.sombraTarjeta,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: bordes,
        border: Border.all(color: esquema.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: bordes,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
