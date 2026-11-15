import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';

/// Protected Variations (Strategy): el cálculo del consumo promedio debe poder
/// ajustarse hasta cumplir el 70 % de RNF-01 sin tocar `ServicioAlertas`.
abstract interface class EstrategiaConsumo {
  /// Consumo promedio diario; [dias] son los días con datos del periodo, sin
  /// los días sin sincronizar (ERS 3.2.2 c).
  Decimal calcularConsumoDiario(
    List<SalidaVenta> salidas,
    List<VentaPerdida> perdidas,
    int dias,
  );
}
