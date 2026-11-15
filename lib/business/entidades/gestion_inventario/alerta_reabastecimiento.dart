import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';

/// Sugerencia verificable de reabastecimiento (RF-05): guarda la existencia
/// del momento (RNF-02) y el consumo con que se calculó, para que el
/// Propietario pueda comprobarla. Provisional si había menos de 30 días de
/// historial (RNF-03). La crea `ServicioAlertas` (CUS-24).
class AlertaReabastecimiento {
  AlertaReabastecimiento(
    this._id,
    this._item,
    this._fecha,
    this._existencia,
    this._consumoPromedioDiario,
    this._diasCobertura,
    this._provisional,
  );

  final String _id;
  final ItemInventario _item;
  final DateTime _fecha;
  final Decimal _existencia;
  final Decimal _consumoPromedioDiario;
  final Decimal _diasCobertura;
  final bool _provisional;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  ItemInventario getItem() => _item;

  /// Día para el que se calculó (día local, sin hora).
  DateTime getFecha() => _fecha;

  /// Existencia del ítem cuando se calculó (RNF-02).
  Decimal getExistencia() => _existencia;

  Decimal getConsumoPromedioDiario() => _consumoPromedioDiario;

  /// existencia / consumo promedio diario.
  Decimal getDiasCobertura() => _diasCobertura;

  /// Verdadero si había menos de 30 días de historial (RNF-03).
  bool isProvisional() => _provisional;
}
