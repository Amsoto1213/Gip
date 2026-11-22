import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';

/// Sugerencia verificable de reabastecimiento (RF-05): guarda la existencia
/// del momento (RNF-02) y el consumo con que se calculó, para que el
/// Propietario pueda comprobarla. Provisional si había menos de 30 días de
/// historial (RNF-03). La crea `ServicioAlertas` (CUS-24).
///
/// Depende de [ItemInventario] solo en el constructor: copia el id del ítem y
/// el id y el nombre de su producto, y no guarda el ítem (DI-57).
class AlertaReabastecimiento {
  AlertaReabastecimiento(
    this._id,
    ItemInventario item,
    this._fecha,
    this._existencia,
    this._consumoPromedioDiario,
    this._diasCobertura,
    this._provisional,
  ) : _itemId = item.getId(),
      _productoId = item.getProducto().getId(),
      _nombreProducto = item.getProducto().getNombre();

  final String _id;
  final String _itemId;
  final String _productoId;
  final String _nombreProducto;
  final DateTime _fecha;
  final Decimal _existencia;
  final Decimal _consumoPromedioDiario;
  final Decimal _diasCobertura;
  final bool _provisional;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  /// Id del ítem para el que se calculó.
  String getItemId() => _itemId;

  /// Id del producto del ítem; con él se cuentan sus ventas perdidas.
  String getProductoId() => _productoId;

  /// Nombre del producto del ítem.
  String getNombreProducto() => _nombreProducto;

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
