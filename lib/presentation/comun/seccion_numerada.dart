import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';

/// Tarjeta de un formulario por pasos: encabezado con el círculo verde del
/// [numero], el [titulo] y, si hay, una [etiqueta] gris ("Obligatorio");
/// debajo una línea divisoria y el contenido.
class SeccionNumerada extends StatelessWidget {
  const SeccionNumerada({
    super.key,
    required this.numero,
    required this.titulo,
    required this.child,
    this.etiqueta,
    this.padding = const EdgeInsets.fromLTRB(24, 22, 24, 22),
  });

  final int numero;
  final String titulo;
  final String? etiqueta;
  final Widget child;

  /// Relleno del contenido. Cero cuando el contenido arma sus propias
  /// columnas (producto | cantidad).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final etiqueta = this.etiqueta;
    return TarjetaGip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: esquema.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$numero',
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: esquema.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Semantics(
                    header: true,
                    child: Text(titulo, style: tema.textTheme.titleLarge),
                  ),
                ),
                if (etiqueta != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tema.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      etiqueta,
                      style: tema.textTheme.labelMedium?.copyWith(
                        fontSize: 13,
                        color: esquema.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
