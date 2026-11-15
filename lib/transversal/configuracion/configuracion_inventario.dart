import 'package:decimal/decimal.dart';

/// Valores del surtido que el diseño marca como configurables.
abstract final class ConfiguracionInventario {
  /// Si |cantidad contada − stock| lo supera, el conteo físico pide revisar
  /// antes de confirmar, sin bloquear (IE-04 b). Hoy es fijo (DI-24); el mismo
  /// número vale para unidades, kilos y libras.
  static final Decimal umbralRevisionConteo = Decimal.fromInt(5);
}
