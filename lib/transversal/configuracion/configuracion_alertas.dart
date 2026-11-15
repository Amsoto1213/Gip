/// Valores de las alertas de reabastecimiento (CUS-24) que el diseño marca
/// como configurables.
abstract final class ConfiguracionAlertas {
  /// Hay alerta cuando la existencia alcanza para menos de estos días
  /// (estricto: 7,0 no alerta; 6,99 sí). Hoy es fijo (DI-25): los mockups
  /// `Alertas` y `wAlertas` muestran alertas de hasta 5 días, así que debe ser
  /// mayor que 5; 7 da una semana de margen para el pedido. Criterio a
  /// confirmar por el equipo.
  static const int umbralDiasCobertura = 7;
}
