import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/comun/tema/tipografia_gip.dart';

/// Cifra pequeña en una tarjeta blanca (mockups `mFiar` y `wFiar`: "Total",
/// "Ya pagó", "Falta"): [etiqueta] arriba, [valor] grande con cifras
/// tabulares y [detalle] debajo. Con [enRojo] el valor va en `errorTexto`
/// (lo que falta o se resta; no es una acción).
class TarjetaCifra extends StatelessWidget {
  const TarjetaCifra({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.detalle,
    this.enRojo = false,
    this.valorKey,
  });

  final String etiqueta;
  final String valor;
  final String? detalle;
  final bool enRojo;
  final Key? valorKey;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final web = FormaGip.esWeb(context);
    return TarjetaGip(
      radio: FormaGip.radioTarjetaMovil,
      padding: EdgeInsets.symmetric(horizontal: web ? 18 : 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              key: valorKey,
              style: tema.textTheme.titleLarge
                  ?.copyWith(color: enRojo ? extra.errorTexto : null)
                  .cifrasTabulares,
            ),
          ),
          if (detalle != null) ...[
            const SizedBox(height: 2),
            Text(
              detalle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
