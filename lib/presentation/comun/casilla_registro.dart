import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Registro que el propietario marca o desmarca (mockups `mConflictos` y
/// `wConflictos`: "Venta del celular de Luis"): una casilla cuadrada, el
/// [titulo] en negrita y, si hay, un [detalle] debajo. Marcada: borde 2 px
/// `primario`, fondo `primarioSuave` y la casilla rellena en verde con su
/// palomita. A diferencia de `OpcionConIcono` (una sola opción), se pueden
/// marcar varias. Alto mínimo 56 px; nulo [onCambio] la deshabilita.
class CasillaRegistro extends StatelessWidget {
  const CasillaRegistro({
    super.key,
    required this.titulo,
    required this.marcada,
    required this.onCambio,
    this.detalle,
  });

  final String titulo;
  final String? detalle;
  final bool marcada;

  /// Recibe el valor nuevo; nulo si no se puede cambiar (por ejemplo, mientras
  /// se guarda).
  final ValueChanged<bool>? onCambio;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final detalle = this.detalle;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: marcada ? esquema.primary : esquema.outlineVariant,
        width: 2,
      ),
    );
    return Semantics(
      checked: marcada,
      enabled: onCambio != null,
      child: Material(
        color: marcada ? esquema.primaryContainer : esquema.surface,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: onCambio == null ? null : () => onCambio!(!marcada),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    key: const Key('casilla'),
                    duration: const Duration(milliseconds: 120),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: marcada ? esquema.primary : esquema.surface,
                      borderRadius: BorderRadius.circular(
                        FormaGip.radioCajaIconoPequena / 2,
                      ),
                      border: Border.all(
                        color: marcada ? esquema.primary : esquema.outline,
                        width: 2,
                      ),
                    ),
                    child: marcada
                        ? Icon(Icons.check, size: 20, color: esquema.onPrimary)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: tema.textTheme.titleSmall),
                        if (detalle != null)
                          Text(
                            detalle,
                            style: tema.textTheme.bodyMedium?.copyWith(
                              color: esquema.onSurfaceVariant,
                            ),
                          ),
                      ],
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
