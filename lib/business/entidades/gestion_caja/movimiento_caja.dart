import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';

/// Movimiento de dinero de la caja: ingreso (venta de contado, abono) o egreso
/// (gasto, retiro personal, devolución por anulación), con su clasificación
/// (RF-10). Solo se agrega (DA-48).
class MovimientoCaja {
  MovimientoCaja(
    this._id,
    this._valor,
    this._descripcion,
    this._clasificacion,
    this._tipo,
    this._fecha,
  );

  final String _id;
  final Decimal _valor;
  final String _descripcion;
  final ClasificacionMovimiento _clasificacion;
  final TipoMovimientoCaja _tipo;
  final DateTime _fecha;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  /// Valor positivo; el tipo dice si entra o sale.
  Decimal getValor() => _valor;

  String getDescripcion() => _descripcion;

  ClasificacionMovimiento getClasificacion() => _clasificacion;

  TipoMovimientoCaja getTipo() => _tipo;

  DateTime getFecha() => _fecha;

  /// Verdadero si el tipo es INGRESO.
  bool esIngreso() => _tipo == TipoMovimientoCaja.ingreso;

  /// Information Expert: verdadero solo si la clasificación es NEGOCIO;
  /// PERSONAL y ANULACION no suman a la utilidad (RF-10).
  bool esDelNegocio() => _clasificacion == ClasificacionMovimiento.negocio;
}
