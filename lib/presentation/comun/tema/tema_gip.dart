import 'package:flutter/material.dart';

/// Colores de `docs/ui/tokens.md`. Los widgets no usan estos valores directo:
/// los toman de `Theme.of(context).colorScheme`.
abstract final class ColoresGip {
  static const primario = Color(0xFF0B6B4B);
  static const primarioOscuro = Color(0xFF08523A);
  static const primarioSuave = Color(0xFFE3F1EA);
  static const fondo = Color(0xFFF3F5F2);
  static const superficie = Color(0xFFFFFFFF);
  static const texto = Color(0xFF13201B);
  static const textoSecundario = Color(0xFF4A5852);
  static const borde = Color(0xFFDCE2DE);
  static const bordeFuerte = Color(0xFFC7D0CB);
  static const error = Color(0xFFB3261E);
  static const errorFondo = Color(0xFFFCE8E6);
}

/// Tema Material 3 del GIP. Las fuentes Archivo e Inter (tokens.md) se agregan
/// cuando se empaqueten en `assets/fonts/`.
abstract final class TemaGip {
  static ThemeData claro() {
    const esquema = ColorScheme(
      brightness: Brightness.light,
      primary: ColoresGip.primario,
      onPrimary: ColoresGip.superficie,
      primaryContainer: ColoresGip.primarioSuave,
      onPrimaryContainer: ColoresGip.primarioOscuro,
      secondary: ColoresGip.primarioOscuro,
      onSecondary: ColoresGip.superficie,
      error: ColoresGip.error,
      onError: ColoresGip.superficie,
      errorContainer: ColoresGip.errorFondo,
      onErrorContainer: ColoresGip.error,
      surface: ColoresGip.superficie,
      onSurface: ColoresGip.texto,
      onSurfaceVariant: ColoresGip.textoSecundario,
      outline: ColoresGip.bordeFuerte,
      outlineVariant: ColoresGip.borde,
    );
    final campoBorde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ColoresGip.bordeFuerte),
    );
    return ThemeData(
      colorScheme: esquema,
      scaffoldBackgroundColor: ColoresGip.fondo,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColoresGip.superficie,
        border: campoBorde,
        enabledBorder: campoBorde,
        focusedBorder: campoBorde.copyWith(
          borderSide: const BorderSide(color: ColoresGip.primario, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
