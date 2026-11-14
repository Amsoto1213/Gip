import 'package:flutter/material.dart';

/// Colores de `docs/ui/tokens.md`. Los widgets no usan estos valores directo:
/// los toman de `Theme.of(context).colorScheme` o de [ColoresExtraGip].
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
  static const separador = Color(0xFFEEF1EF);
  static const alerta = Color(0xFFF2A500);
  static const alertaFondo = Color(0xFFFFF4D6);
  static const alertaBorde = Color(0xFFF2C14E);
  static const alertaTexto = Color(0xFF6B4200);
  static const info = Color(0xFFE4EDF9);
  static const infoTexto = Color(0xFF1E3F73);
  static const error = Color(0xFFB3261E);
  static const errorFondo = Color(0xFFFCE8E6);

  /// rgba(12, 21, 18, 0.55): fondo detrás de hojas modales.
  static const velo = Color(0x8C0C1512);
}

/// Tokens sin lugar en `ColorScheme`: alerta de poca existencia, indicador
/// "Sin internet" (RNF-09) y separador. Se leen con
/// `Theme.of(context).extension<ColoresExtraGip>()!`.
@immutable
class ColoresExtraGip extends ThemeExtension<ColoresExtraGip> {
  const ColoresExtraGip({
    required this.separador,
    required this.alerta,
    required this.alertaFondo,
    required this.alertaBorde,
    required this.alertaTexto,
    required this.info,
    required this.infoTexto,
  });

  static const claro = ColoresExtraGip(
    separador: ColoresGip.separador,
    alerta: ColoresGip.alerta,
    alertaFondo: ColoresGip.alertaFondo,
    alertaBorde: ColoresGip.alertaBorde,
    alertaTexto: ColoresGip.alertaTexto,
    info: ColoresGip.info,
    infoTexto: ColoresGip.infoTexto,
  );

  final Color separador;
  final Color alerta;
  final Color alertaFondo;
  final Color alertaBorde;
  final Color alertaTexto;
  final Color info;
  final Color infoTexto;

  @override
  ColoresExtraGip copyWith({
    Color? separador,
    Color? alerta,
    Color? alertaFondo,
    Color? alertaBorde,
    Color? alertaTexto,
    Color? info,
    Color? infoTexto,
  }) => ColoresExtraGip(
    separador: separador ?? this.separador,
    alerta: alerta ?? this.alerta,
    alertaFondo: alertaFondo ?? this.alertaFondo,
    alertaBorde: alertaBorde ?? this.alertaBorde,
    alertaTexto: alertaTexto ?? this.alertaTexto,
    info: info ?? this.info,
    infoTexto: infoTexto ?? this.infoTexto,
  );

  @override
  ColoresExtraGip lerp(ColoresExtraGip? other, double t) {
    if (other == null) return this;
    return ColoresExtraGip(
      separador: Color.lerp(separador, other.separador, t)!,
      alerta: Color.lerp(alerta, other.alerta, t)!,
      alertaFondo: Color.lerp(alertaFondo, other.alertaFondo, t)!,
      alertaBorde: Color.lerp(alertaBorde, other.alertaBorde, t)!,
      alertaTexto: Color.lerp(alertaTexto, other.alertaTexto, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoTexto: Color.lerp(infoTexto, other.infoTexto, t)!,
    );
  }
}
