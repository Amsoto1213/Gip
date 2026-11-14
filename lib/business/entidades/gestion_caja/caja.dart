import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/transversal/errores/errores_caja.dart';

/// Caja del día de una tienda; agrupa sus movimientos de dinero. Su id se forma
/// con la tienda y la fecha (DA-62, DI-21). El saldo esperado se calcula de los
/// movimientos y no se guarda (DA-48).
///
/// Por ahora sin el cierre (CUS-14): la caja siempre está abierta (DI-21).
class Caja {
  Caja(this._id, this._fecha);

  final String _id;
  final DateTime _fecha;
  final List<MovimientoCaja> _movimientos = [];
  // Lo cambia cerrar(), que llega con CUS-14.
  // ignore: prefer_final_fields
  bool _cerrada = false;

  /// Identificador: tienda y fecha (DA-62).
  String getId() => _id;

  /// Día de la caja (fecha local, sin hora; DI-21).
  DateTime getFecha() => _fecha;

  bool isCerrada() => _cerrada;

  List<MovimientoCaja> getMovimientos() => List.unmodifiable(_movimientos);

  /// Information Expert: rechaza si la caja está cerrada; si no, agrega el
  /// movimiento a su lista.
  MovimientoCaja registrarMovimiento(MovimientoCaja movimiento) {
    if (_cerrada) throw const ExcepcionCajaCerrada();
    _movimientos.add(movimiento);
    return movimiento;
  }

  /// Information Expert: suma los ingresos y resta los egresos (DA-48, DA-62).
  Decimal calcularSaldoEsperado() => _movimientos.fold(
    Decimal.zero,
    (saldo, m) => m.esIngreso() ? saldo + m.getValor() : saldo - m.getValor(),
  );
}
