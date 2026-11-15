import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/comun/tema/tipografia_gip.dart';

export 'colores_gip.dart';
export 'forma_gip.dart';
export 'tipografia_gip.dart';

/// Tema Material 3 del GIP con los tokens de `docs/ui/tokens.md`.
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
      inverseSurface: ColoresGip.texto,
      onInverseSurface: ColoresGip.superficie,
      scrim: ColoresGip.velo,
    );
    final textos = TipografiaGip.textTheme();
    final campoBorde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(FormaGip.radioCampo),
      borderSide: const BorderSide(
        color: ColoresGip.bordeFuerte,
        width: FormaGip.grosorBordeCampo,
      ),
    );

    return ThemeData(
      colorScheme: esquema,
      fontFamily: TipografiaGip.texto,
      textTheme: textos,
      scaffoldBackgroundColor: ColoresGip.fondo,
      extensions: const [ColoresExtraGip.claro],
      dividerTheme: const DividerThemeData(
        color: ColoresGip.separador,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: ColoresGip.superficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FormaGip.radioTarjeta),
          side: const BorderSide(color: ColoresGip.borde),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColoresGip.superficie,
        modalBarrierColor: ColoresGip.velo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColoresGip.superficie,
        border: campoBorde,
        enabledBorder: campoBorde,
        focusedBorder: campoBorde.copyWith(
          borderSide: const BorderSide(
            color: ColoresGip.primario,
            width: FormaGip.grosorBordeCampo,
          ),
        ),
        hintStyle: textos.bodyLarge!.copyWith(
          color: ColoresGip.textoSecundario,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  FormaGip.radioBotonPrimario,
                ),
              ),
              textStyle: textos.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ).copyWith(
              // Hover y presionado con primarioOscuro (rediseño).
              backgroundColor: WidgetStateProperty.resolveWith(
                (estados) => estados.contains(WidgetState.disabled)
                    ? null
                    : estados.contains(WidgetState.pressed) ||
                          estados.contains(WidgetState.hovered)
                    ? ColoresGip.primarioOscuro
                    : ColoresGip.primario,
              ),
            ),
      ),
      // Opción única ("Se vende por"): 52 px, radio 14, la elegida en verde
      // suave con texto verde (las acciones van solo en verde, rediseño).
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FormaGip.radioCampo),
            ),
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(
              color: ColoresGip.bordeFuerte,
              width: FormaGip.grosorBordeCampo,
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            textos.labelLarge!.copyWith(fontWeight: FontWeight.w700),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.selected)
                ? ColoresGip.primarioSuave
                : ColoresGip.superficie,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.selected)
                ? ColoresGip.primario
                : ColoresGip.texto,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          side: const BorderSide(
            color: ColoresGip.bordeFuerte,
            width: FormaGip.grosorBordeCampo,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FormaGip.radioCampo),
          ),
        ),
      ),
    );
  }
}
