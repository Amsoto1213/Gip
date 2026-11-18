import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/transversal/errores/errores_caja.dart';

/// Caja del día de una tienda; agrupa sus movimientos de dinero. Su id se forma
/// con la tienda y la fecha (DA-62, DI-21). El saldo esperado se calcula de los
/// movimientos y no se guarda (DA-48).
///
/// Se cierra una vez al día con [cerrar] (CUS-14): guarda lo que se contó, la
/// diferencia con el saldo esperado y el instante del cierre; desde entonces
/// rechaza nuevos movimientos. `recalcularDiferencia` llega con CUS-23.
class Caja {
  /// [movimientos] y los datos del cierre ([efectivoContado], [diferencia] y
  /// [fechaCierre], los tres juntos) sirven para armar una caja que ya estaba
  /// guardada; no están en EA (DI-37). Con ellos, la caja nace cerrada.
  Caja(
    this._id,
    this._fecha, {
    List<MovimientoCaja> movimientos = const [],
    this._efectivoContado,
    this._diferencia,
    this._fechaCierre,
  }) : _cerrada = _efectivoContado != null {
    _movimientos.addAll(movimientos);
  }

  final String _id;
  final DateTime _fecha;
  final List<MovimientoCaja> _movimientos = [];
  bool _cerrada;
  Decimal? _efectivoContado;
  Decimal? _diferencia;
  DateTime? _fechaCierre;

  /// Identificador: tienda y fecha (DA-62).
  String getId() => _id;

  /// Día de la caja (fecha local, sin hora; DI-21).
  DateTime getFecha() => _fecha;

  bool isCerrada() => _cerrada;

  /// Efectivo que se contó al cerrar, o null mientras está abierta.
  Decimal? getEfectivoContado() => _efectivoContado;

  /// Efectivo contado menos saldo esperado: positivo es sobrante y negativo
  /// faltante (RF-13). Null mientras está abierta.
  Decimal? getDiferencia() => _diferencia;

  /// Instante del cierre en UTC, o null mientras está abierta.
  DateTime? getFechaCierre() => _fechaCierre;

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

  /// Information Expert: rechaza si ya está cerrada; si no, diferencia =
  /// [efectivoContado] − saldo esperado, guarda el efectivo, la diferencia y la
  /// fecha del cierre, queda cerrada y devuelve la diferencia (RF-13).
  Decimal cerrar(Decimal efectivoContado) {
    if (_cerrada) throw const ExcepcionCajaCerrada();
    final diferencia = efectivoContado - calcularSaldoEsperado();
    _efectivoContado = efectivoContado;
    _diferencia = diferencia;
    _fechaCierre = DateTime.now().toUtc();
    _cerrada = true;
    return diferencia;
  }
}
