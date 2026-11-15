import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/tipografia_gip.dart';

/// Fila de una lista de opción única (mockups `mFiar` y `wFiar`: los clientes
/// encontrados): círculo de radio, [titulo] en negrita, [subtitulo] y, a la
/// derecha, [valor] (en `errorTexto` con [valorEnRojo]). Elegida: fondo
/// `primarioSuave` y radio `primario`. Sin borde propio: va dentro de una
/// `TarjetaGip` con separadores. Alto mínimo 56 px.
class OpcionRadio extends StatelessWidget {
  const OpcionRadio({
    super.key,
    required this.titulo,
    required this.elegida,
    required this.onTap,
    this.subtitulo,
    this.valor,
    this.valorEnRojo = false,
  });

  final String titulo;
  final String? subtitulo;
  final String? valor;
  final bool valorEnRojo;
  final bool elegida;

  /// Nulo si no se puede elegir.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final extra = tema.extension<ColoresExtraGip>()!;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: elegida,
      button: true,
      child: Material(
        color: elegida ? esquema.primaryContainer : esquema.surface,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    elegida
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 26,
                    color: elegida ? esquema.primary : esquema.onSurfaceVariant,
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
                        if (subtitulo != null && subtitulo!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(subtitulo!, style: tema.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  if (valor != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      valor!,
                      style: tema.textTheme.titleSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: valorEnRojo ? extra.errorTexto : null,
                          )
                          .cifrasTabulares,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
