import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';

/// Movimiento de stock con cantidad con signo: positiva suma, negativa resta
/// (DA-19, ERS 3.2.1). Solo se agrega; se anula cambiando su estado, nunca se
/// borra ni se edita (RNF-15).
abstract class MovimientoInventario {
  /// Nace VIGENTE.
  MovimientoInventario(this._id, this._item, this._cantidad, this._fecha);

  final String _id;
  final ItemInventario _item;
  final Decimal _cantidad;
  final DateTime _fecha;
  EstadoMovimiento _estado = EstadoMovimiento.vigente;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  ItemInventario getItem() => _item;

  /// Cantidad con signo: positiva suma al stock, negativa resta.
  Decimal getCantidad() => _cantidad;

  DateTime getFecha() => _fecha;

  EstadoMovimiento getEstado() => _estado;

  /// Lo cambian ServicioConciliacion y ServicioInventario.anularMovimiento.
  void setEstado(EstadoMovimiento estado) => _estado = estado;
}
