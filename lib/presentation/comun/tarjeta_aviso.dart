import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Tarjeta de aviso en rojo (`conteo-web.html`): fondo `errorFondo`, borde
/// `errorBorde`, radio 22, caja blanca de 44 px con el ícono en `error`, y
/// [titulo] (16 px, 700) y [texto] (14 px) en `errorTexto`. Marca un estado
/// que hay que revisar; no es una acción. Se anuncia al aparecer.
class TarjetaAviso extends StatelessWidget {
  const TarjetaAviso({
    super.key,
    required this.titulo,
    required this.texto,
    this.icono = Icons.warning_amber_rounded,
  });

  final String titulo;
  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final extra = tema.extension<ColoresExtraGip>()!;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          color: esquema.errorContainer,
          borderRadius: BorderRadius.circular(FormaGip.radioTarjeta),
          border: Border.all(color: extra.errorBorde),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: esquema.surface,
                borderRadius: BorderRadius.circular(
                  FormaGip.radioCajaIconoPequena,
                ),
              ),
              child: Icon(icono, size: 22, color: esquema.error),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: tema.textTheme.titleSmall?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: extra.errorTexto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    texto,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.45,
                      color: extra.errorTexto,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
