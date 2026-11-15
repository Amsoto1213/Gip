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

  /// Fila de una lista con un valor por revisar o con error (conteo).
  static const errorFondoSuave = Color(0xFFFFF5F4);

  /// Borde de la tarjeta de aviso en rojo.
  static const errorBorde = Color(0xFFF3C1BC);

  /// Texto sobre `errorFondo` en la tarjeta de aviso.
  static const errorTexto = Color(0xFF8C1D18);

  /// rgba(12, 21, 18, 0.55): fondo detrás de hojas modales.
  static const velo = Color(0x8C0C1512);

  // Rediseño visual (`docs/ui/rediseno/README.md`).

  /// Encabezados de tabla, filas al pasar el mouse, caja del producto.
  static const superficieSuave = Color(0xFFF7F9F7);

  /// Botones − y + de la cantidad.
  static const pasoFondo = Color(0xFFEEF3F0);

  /// Botones − y + con el mouse encima (prototipo `perdida-web.html`).
  static const pasoFondoActivo = Color(0xFFDCE7E1);

  /// Menú lateral web y caja oscura del resumen.
  static const navFondo = Color(0xFF13201B);
  static const navTexto = Color(0xFFC9D3CE);
  static const navTextoSecundario = Color(0xFF9FB0A8);

  /// Círculos decorativos del panel verde del inicio de sesión.
  static const verdeCirculoClaro = Color(0xFF0E7A56);
  static const verdeCirculoOscuro = Color(0xFF095C40);
}

/// Tokens sin lugar en `ColorScheme`: alerta de poca existencia, indicador
/// "Sin internet" (RNF-09), separador, los tonos de error de una fila o un
/// aviso y los del rediseño (menú lateral, botones de paso, panel del inicio
/// de sesión). Se leen con
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
    required this.errorFondoSuave,
    required this.errorBorde,
    required this.errorTexto,
    required this.superficieSuave,
    required this.pasoFondo,
    required this.pasoFondoActivo,
    required this.navFondo,
    required this.navTexto,
    required this.navTextoSecundario,
    required this.verdeCirculoClaro,
    required this.verdeCirculoOscuro,
  });

  static const claro = ColoresExtraGip(
    separador: ColoresGip.separador,
    alerta: ColoresGip.alerta,
    alertaFondo: ColoresGip.alertaFondo,
    alertaBorde: ColoresGip.alertaBorde,
    alertaTexto: ColoresGip.alertaTexto,
    info: ColoresGip.info,
    infoTexto: ColoresGip.infoTexto,
    errorFondoSuave: ColoresGip.errorFondoSuave,
    errorBorde: ColoresGip.errorBorde,
    errorTexto: ColoresGip.errorTexto,
    superficieSuave: ColoresGip.superficieSuave,
    pasoFondo: ColoresGip.pasoFondo,
    pasoFondoActivo: ColoresGip.pasoFondoActivo,
    navFondo: ColoresGip.navFondo,
    navTexto: ColoresGip.navTexto,
    navTextoSecundario: ColoresGip.navTextoSecundario,
    verdeCirculoClaro: ColoresGip.verdeCirculoClaro,
    verdeCirculoOscuro: ColoresGip.verdeCirculoOscuro,
  );

  final Color separador;
  final Color alerta;
  final Color alertaFondo;
  final Color alertaBorde;
  final Color alertaTexto;
  final Color info;
  final Color infoTexto;
  final Color errorFondoSuave;
  final Color errorBorde;
  final Color errorTexto;
  final Color superficieSuave;
  final Color pasoFondo;
  final Color pasoFondoActivo;
  final Color navFondo;
  final Color navTexto;
  final Color navTextoSecundario;
  final Color verdeCirculoClaro;
  final Color verdeCirculoOscuro;

  @override
  ColoresExtraGip copyWith({
    Color? separador,
    Color? alerta,
    Color? alertaFondo,
    Color? alertaBorde,
    Color? alertaTexto,
    Color? info,
    Color? infoTexto,
    Color? errorFondoSuave,
    Color? errorBorde,
    Color? errorTexto,
    Color? superficieSuave,
    Color? pasoFondo,
    Color? pasoFondoActivo,
    Color? navFondo,
    Color? navTexto,
    Color? navTextoSecundario,
    Color? verdeCirculoClaro,
    Color? verdeCirculoOscuro,
  }) => ColoresExtraGip(
    separador: separador ?? this.separador,
    alerta: alerta ?? this.alerta,
    alertaFondo: alertaFondo ?? this.alertaFondo,
    alertaBorde: alertaBorde ?? this.alertaBorde,
    alertaTexto: alertaTexto ?? this.alertaTexto,
    info: info ?? this.info,
    infoTexto: infoTexto ?? this.infoTexto,
    errorFondoSuave: errorFondoSuave ?? this.errorFondoSuave,
    errorBorde: errorBorde ?? this.errorBorde,
    errorTexto: errorTexto ?? this.errorTexto,
    superficieSuave: superficieSuave ?? this.superficieSuave,
    pasoFondo: pasoFondo ?? this.pasoFondo,
    pasoFondoActivo: pasoFondoActivo ?? this.pasoFondoActivo,
    navFondo: navFondo ?? this.navFondo,
    navTexto: navTexto ?? this.navTexto,
    navTextoSecundario: navTextoSecundario ?? this.navTextoSecundario,
    verdeCirculoClaro: verdeCirculoClaro ?? this.verdeCirculoClaro,
    verdeCirculoOscuro: verdeCirculoOscuro ?? this.verdeCirculoOscuro,
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
      errorFondoSuave: Color.lerp(errorFondoSuave, other.errorFondoSuave, t)!,
      errorBorde: Color.lerp(errorBorde, other.errorBorde, t)!,
      errorTexto: Color.lerp(errorTexto, other.errorTexto, t)!,
      superficieSuave: Color.lerp(superficieSuave, other.superficieSuave, t)!,
      pasoFondo: Color.lerp(pasoFondo, other.pasoFondo, t)!,
      pasoFondoActivo: Color.lerp(pasoFondoActivo, other.pasoFondoActivo, t)!,
      navFondo: Color.lerp(navFondo, other.navFondo, t)!,
      navTexto: Color.lerp(navTexto, other.navTexto, t)!,
      navTextoSecundario: Color.lerp(
        navTextoSecundario,
        other.navTextoSecundario,
        t,
      )!,
      verdeCirculoClaro: Color.lerp(
        verdeCirculoClaro,
        other.verdeCirculoClaro,
        t,
      )!,
      verdeCirculoOscuro: Color.lerp(
        verdeCirculoOscuro,
        other.verdeCirculoOscuro,
        t,
      )!,
    );
  }
}
