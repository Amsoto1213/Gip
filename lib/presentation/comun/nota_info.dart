import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Nota informativa en azul (mockups `Alertas` y `wAlertas`): fondo `info`,
/// borde `info` un poco más oscuro, ícono de información y el texto en
/// `infoTexto`, con [destacado] en negrilla al comienzo ("Provisional = …").
/// Explica cómo leer un dato; no es una acción ni un error.
class NotaInfo extends StatelessWidget {
  const NotaInfo({super.key, required this.texto, this.destacado});

  final String texto;

  /// Palabra o frase en negrilla antes de [texto].
  final String? destacado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final estilo = tema.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      height: 1.45,
      color: extra.infoTexto,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: extra.info,
        borderRadius: BorderRadius.circular(FormaGip.radioCampo),
        border: Border.all(color: extra.infoTexto.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 20, color: extra.infoTexto),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (destacado case final destacado?)
                    TextSpan(
                      text: '$destacado ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  TextSpan(text: texto),
                ],
              ),
              style: estilo,
            ),
          ),
        ],
      ),
    );
  }
}
