import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/tipografia_gip.dart';

export 'colores_gip.dart';
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
      // Barra lateral oscura de la web.
      inverseSurface: ColoresGip.texto,
      onInverseSurface: ColoresGip.superficie,
      scrim: ColoresGip.velo,
    );
    final textos = TipografiaGip.textTheme();
    final campoBorde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ColoresGip.bordeFuerte),
    );
    final etiquetaNavegacion = textos.labelMedium!;

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
          borderRadius: BorderRadius.circular(16),
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
          borderSide: const BorderSide(color: ColoresGip.primario, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textos.titleMedium!.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          side: const BorderSide(color: ColoresGip.bordeFuerte),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      // Barra inferior del móvil: 72 px, activo en verde sin "píldora".
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: ColoresGip.superficie,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            size: 26,
            color: estados.contains(WidgetState.selected)
                ? ColoresGip.primario
                : ColoresGip.textoSecundario,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => etiquetaNavegacion.copyWith(
            color: estados.contains(WidgetState.selected)
                ? ColoresGip.primario
                : ColoresGip.textoSecundario,
          ),
        ),
      ),
      // Barra lateral de la web: fondo oscuro y activo en verde.
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: ColoresGip.texto,
        indicatorColor: ColoresGip.primario,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        selectedIconTheme: const IconThemeData(
          size: 24,
          color: ColoresGip.superficie,
        ),
        unselectedIconTheme: const IconThemeData(
          size: 24,
          color: ColoresGip.bordeFuerte,
        ),
        selectedLabelTextStyle: textos.labelLarge!.copyWith(
          color: ColoresGip.superficie,
        ),
        unselectedLabelTextStyle: textos.labelLarge!.copyWith(
          fontWeight: FontWeight.w500,
          color: ColoresGip.bordeFuerte,
        ),
      ),
    );
  }
}
