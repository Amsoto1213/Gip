import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';

/// Diferencia entre lo contado y el stock en un conteo físico; prevalece lo
/// contado (RF-04). La cantidad es la diferencia con signo (contada − stock),
/// así que puede ser positiva, negativa o cero (DI-24).
class AjusteConteo extends MovimientoInventario {
  AjusteConteo(
    super.id,
    super.item,
    super.cantidad,
    super.fecha,
    this._cantidadContada,
  );

  final Decimal _cantidadContada;

  Decimal getCantidadContada() => _cantidadContada;
}
