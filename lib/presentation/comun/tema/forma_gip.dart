import 'package:flutter/material.dart';

/// Radios, sombras y medidas del rediseño (`docs/ui/rediseno/README.md`).
/// Los componentes de `comun/` los usan; las pantallas usan los componentes.
abstract final class FormaGip {
  // Radios.
  static const radioTarjeta = 22.0;

  /// Tarjetas del móvil en listas densas (avance y filas del conteo).
  static const radioTarjetaMovil = 18.0;
  static const radioTarjetaAccion = 20.0;
  static const radioCajaIcono = 16.0;
  static const radioCajaIconoPequena = 14.0;

  /// Caja de 40 px con el ícono del producto en una fila de tabla.
  static const radioCajaIconoTabla = 12.0;
  static const radioCampo = 14.0;
  static const radioBotonPrimario = 16.0;
  static const radioChip = 999.0;

  /// Grupo de pestañas de filtro (14) y cada pestaña dentro (11).
  static const radioPestanas = 14.0;
  static const radioPestana = 11.0;

  /// Borde de campos y botones de contorno.
  static const grosorBordeCampo = 1.5;

  /// Alto del botón principal (56–58 px).
  static const altoBotonPrimario = 58.0;

  /// Ancho desde el que una pantalla usa la versión web (dos columnas,
  /// títulos de 34 px).
  static const anchoWeb = 720.0;

  /// `0 1px 2px rgba(19,32,27,0.04), 0 8px 24px rgba(19,32,27,0.05)`.
  static const sombraTarjeta = [
    BoxShadow(color: Color(0x0A13201B), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0D13201B), offset: Offset(0, 8), blurRadius: 24),
  ];

  /// `0 1px 2px rgba(19,32,27,0.04), 0 22px 56px rgba(19,32,27,0.10)`.
  static const sombraElevada = [
    BoxShadow(color: Color(0x0A13201B), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x1A13201B), offset: Offset(0, 22), blurRadius: 56),
  ];

  /// Tarjeta de acción con el mouse encima: `0 10px 28px rgba(19,32,27,0.10)`.
  static const sombraTarjetaActiva = [
    BoxShadow(color: Color(0x1A13201B), offset: Offset(0, 10), blurRadius: 28),
  ];

  /// `0 6px 16px rgba(11,107,75,0.28)`.
  static const sombraBotonPrimario = [
    BoxShadow(color: Color(0x470B6B4B), offset: Offset(0, 6), blurRadius: 16),
  ];

  /// Logo sobre el panel verde: `0 24px 60px rgba(5,40,28,0.35)`.
  static const sombraLogo = [
    BoxShadow(color: Color(0x5905281C), offset: Offset(0, 24), blurRadius: 60),
  ];

  /// Pestaña de filtro elegida: `0 1px 3px rgba(19,32,27,0.12)`.
  static const sombraPestana = [
    BoxShadow(color: Color(0x1F13201B), offset: Offset(0, 1), blurRadius: 3),
  ];

  /// Halo de foco de los campos: 4 px de `rgba(11,107,75,0.14)`.
  static const haloFoco = [
    BoxShadow(color: Color(0x240B6B4B), spreadRadius: 4),
  ];

  /// Verdadero si [context] tiene el ancho de la versión web.
  static bool esWeb(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= anchoWeb;
}
