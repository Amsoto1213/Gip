import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/comun/tema/tipografia_gip.dart';

/// Resumen de un movimiento de surtido. Arriba, una caja oscura (`navFondo`)
/// con "Hay ahora N → Quedará en N" (el segundo número en una píldora
/// `primario`) y, si hay [fraccionQueda], una barra con lo que queda en
/// `primario` y lo que se quita en blanco. Debajo, las filas de [detalles] y
/// el [pie] (mensajes, botón principal, cancelar, nota).
class ResumenMovimiento extends StatelessWidget {
  const ResumenMovimiento({
    super.key,
    required this.antes,
    required this.despues,
    this.titulo = 'Resumen',
    this.etiquetaAntes = 'Hay ahora',
    this.etiquetaDespues = 'Quedará en',
    this.fraccionQueda,
    this.detalles = const [],
    this.pie = const [],
  });

  final String titulo;

  /// Existencia antes del movimiento ("14", o "—" si no se sabe).
  final String antes;

  /// Existencia después del movimiento.
  final String despues;
  final String etiquetaAntes;
  final String etiquetaDespues;

  /// Parte de la existencia que queda (0 a 1). Nula: sin barra (en una
  /// entrada el surtido sube y no se quita nada).
  final double? fraccionQueda;
  final List<FilaDetalle> detalles;
  final List<Widget> pie;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final extra = tema.extension<ColoresExtraGip>()!;
    final numero = tema.textTheme.headlineLarge!
        .copyWith(fontSize: 36, color: esquema.onPrimary, height: 1.15)
        .cifrasTabulares;
    final etiqueta = tema.textTheme.bodySmall?.copyWith(
      fontSize: 13,
      color: extra.navTextoSecundario,
    );
    final fraccion = fraccionQueda;

    final caja = Container(
      color: extra.navFondo,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              titulo,
              style: tema.textTheme.titleLarge?.copyWith(
                color: esquema.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(etiquetaAntes, style: etiqueta),
                    const SizedBox(height: 2),
                    Text(antes, key: const Key('resumen_antes'), style: numero),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 28,
                color: extra.navTextoSecundario,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(etiquetaDespues, style: etiqueta),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: esquema.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        despues,
                        key: const Key('resumen_despues'),
                        style: numero.copyWith(fontSize: 34, height: 50 / 34),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (fraccion != null) ...[
            const SizedBox(height: 14),
            ExcludeSemantics(
              child: Container(
                key: const Key('resumen_barra'),
                height: 8,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: esquema.surface,
                  borderRadius: BorderRadius.circular(FormaGip.radioChip),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraccion.clamp(0, 1),
                  child: ColoredBox(color: esquema.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return TarjetaGip(
      elevada: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          caja,
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < detalles.length; i++) ...[
                  if (i > 0) const Divider(),
                  detalles[i],
                ],
                if (detalles.isNotEmpty && pie.isNotEmpty)
                  const SizedBox(height: 14),
                ...pie,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila etiqueta / valor del resumen. Con [resta] el valor va en `error`
/// (lo que sale del surtido).
class FilaDetalle extends StatelessWidget {
  const FilaDetalle(this.etiqueta, this.valor, {super.key, this.resta = false});

  final String etiqueta;
  final String valor;
  final bool resta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: tema.textTheme.bodyMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: resta ? tema.colorScheme.error : null,
                  )
                  .cifrasTabulares,
            ),
          ),
        ],
      ),
    );
  }
}
