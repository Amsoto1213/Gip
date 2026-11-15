import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_inventario/estrategia_consumo.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';

/// Primera estrategia: unidades vendidas más una por cada venta perdida,
/// dividido entre los días con datos.
class ConsumoPromedioSimple implements EstrategiaConsumo {
  ConsumoPromedioSimple();

  /// Decimales con que se redondea el consumo (mitad hacia arriba).
  static const escala = 4;

  /// Suma `salida.calcularUnidades()` (valor absoluto) más una unidad por
  /// venta perdida y divide entre [dias]. Sin días con datos devuelve cero,
  /// para no dividir entre cero.
  @override
  Decimal calcularConsumoDiario(
    List<SalidaVenta> salidas,
    List<VentaPerdida> perdidas,
    int dias,
  ) {
    if (dias <= 0) return Decimal.zero;
    final unidades = salidas.fold(
      Decimal.fromInt(perdidas.length),
      (suma, salida) => suma + salida.calcularUnidades(),
    );
    return (unidades / Decimal.fromInt(dias))
        .toDecimal(scaleOnInfinitePrecision: escala + 2)
        .round(scale: escala);
  }
}
