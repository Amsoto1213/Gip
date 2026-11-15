import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Opción seleccionable de una lista cerrada (p. ej. el motivo de una
/// pérdida): caja de [icono], [titulo], [descripcion] y, si está [elegida],
/// el círculo de verificación. Elegida: borde 2 px `primario` y fondo
/// `primarioSuave`.
class OpcionConIcono extends StatelessWidget {
  const OpcionConIcono({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.elegida,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final bool elegida;

  /// Nulo si no se puede elegir (p. ej. mientras se guarda).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: elegida ? esquema.primary : esquema.outlineVariant,
        width: 2,
      ),
    );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: elegida,
      button: true,
      child: Material(
        color: elegida ? esquema.primaryContainer : esquema.surface,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: elegida
                        ? esquema.surface
                        : tema.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(
                      FormaGip.radioCajaIconoPequena,
                    ),
                  ),
                  child: Icon(
                    icono,
                    size: 22,
                    color: elegida ? esquema.primary : esquema.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: tema.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        descripcion,
                        style: tema.textTheme.bodySmall?.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (elegida) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 22, color: esquema.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
