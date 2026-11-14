import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';

/// Tipografía de `docs/ui/tokens.md`: títulos en Archivo 800 y texto en Inter.
/// Las fuentes están en `assets/fonts/` (funcionan sin internet).
abstract final class TipografiaGip {
  static const titulos = 'Archivo';
  static const texto = 'Inter';

  static TextTheme textTheme() {
    const titulo = TextStyle(
      fontFamily: titulos,
      fontWeight: FontWeight.w800,
      color: ColoresGip.texto,
      height: 1.15,
    );
    const cuerpo = TextStyle(
      fontFamily: texto,
      fontWeight: FontWeight.w400,
      color: ColoresGip.texto,
      height: 1.35,
    );
    return TextTheme(
      // Título de pantalla en móvil.
      headlineLarge: titulo.copyWith(fontSize: 30),
      // Título de pantallas internas.
      headlineMedium: titulo.copyWith(fontSize: 23),
      // Secciones (19–22 px).
      headlineSmall: titulo.copyWith(fontSize: 22),
      titleLarge: titulo.copyWith(fontSize: 19),
      titleMedium: cuerpo.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      titleSmall: cuerpo.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      bodyLarge: cuerpo.copyWith(fontSize: 16),
      bodyMedium: cuerpo.copyWith(fontSize: 15),
      bodySmall: cuerpo.copyWith(
        fontSize: 14,
        color: ColoresGip.textoSecundario,
      ),
      labelLarge: cuerpo.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      labelMedium: cuerpo.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      labelSmall: cuerpo.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

/// Montos con cifras tabulares para que las columnas de precios se alineen.
extension CifrasTabulares on TextStyle {
  TextStyle get cifrasTabulares =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
