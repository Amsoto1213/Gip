import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

const _meses = [
  'ene.',
  'feb.',
  'mar.',
  'abr.',
  'may.',
  'jun.',
  'jul.',
  'ago.',
  'sep.',
  'oct.',
  'nov.',
  'dic.',
];

/// Un día como lo lee el tendero: "1 oct. 2026".
String textoDia(DateTime dia) =>
    '${dia.day} ${_meses[dia.month - 1]} ${dia.year}';

/// Campo de una fecha (mockups `mExportar` y `wExportar`: Desde y Hasta): la
/// [etiqueta] arriba y, en una caja del alto de `CampoGip` (54 px), el día
/// elegido con el ícono de calendario. Tocarlo llama a [onTap], que abre el
/// selector de fechas; el campo no se escribe a mano. Con [error] el borde
/// pasa a `error` y el mensaje va debajo. Nulo [onTap] = deshabilitado.
class CampoFecha extends StatelessWidget {
  const CampoFecha({
    super.key,
    required this.etiqueta,
    required this.fecha,
    required this.onTap,
    this.error,
  });

  final String etiqueta;
  final DateTime fecha;

  /// Abre el selector de fechas; nulo si no se puede cambiar.
  final VoidCallback? onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(FormaGip.radioCampo),
      side: BorderSide(
        color: error != null ? esquema.error : esquema.outline,
        width: error != null ? FormaGip.grosorBordeCampo : 1,
      ),
    );
    final texto = textoDia(fecha);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etiqueta, style: tema.textTheme.labelMedium),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          enabled: onTap != null,
          label: '$etiqueta: $texto',
          excludeSemantics: true,
          child: Material(
            color: esquema.surface,
            shape: forma,
            child: InkWell(
              customBorder: forma,
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(texto, style: tema.textTheme.bodyLarge),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: esquema.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: tema.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: esquema.error,
            ),
          ),
        ],
      ],
    );
  }
}
