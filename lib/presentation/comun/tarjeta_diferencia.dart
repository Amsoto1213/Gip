import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/comun/tema/tipografia_gip.dart';

/// Cómo quedó la cuenta del efectivo contado frente al esperado.
enum TonoDiferencia { faltante, sobrante, cuadra }

/// Resultado de contar la caja (mockups `mCierre` y `wCierre`): [titulo]
/// ("Faltan", "Sobran", "La caja cuadra") a la izquierda y [valor] grande con
/// cifras tabulares a la derecha. El faltante va en amarillo (estado, no
/// acción: `alertaFondo`, `alertaBorde` y `alertaTexto`); el sobrante y el
/// cuadre, en verde suave (`primarioSuave`). Se anuncia al aparecer.
class TarjetaDiferencia extends StatelessWidget {
  const TarjetaDiferencia({
    super.key,
    required this.tono,
    required this.titulo,
    this.valor,
  });

  final TonoDiferencia tono;
  final String titulo;

  /// Monto ya formateado ("$ 3.500"). Sin él (la caja cuadra) solo va el título.
  final String? valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final extra = tema.extension<ColoresExtraGip>()!;
    final falta = tono == TonoDiferencia.faltante;
    final fondo = falta ? extra.alertaFondo : esquema.primaryContainer;
    final borde = falta ? extra.alertaBorde : esquema.primary;
    final color = falta ? extra.alertaTexto : esquema.onPrimaryContainer;
    final valor = this.valor;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(FormaGip.radioCampo),
          border: Border.all(color: borde.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Icon(
              falta ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titulo,
                style: tema.textTheme.titleMedium?.copyWith(color: color),
              ),
            ),
            if (valor != null)
              Text(
                valor,
                key: const Key('diferencia_valor'),
                style: tema.textTheme.headlineSmall
                    ?.copyWith(color: color)
                    .cifrasTabulares,
              ),
          ],
        ),
      ),
    );
  }
}
