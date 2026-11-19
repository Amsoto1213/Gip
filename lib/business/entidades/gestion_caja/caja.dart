import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/desglose_caja.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/transversal/errores/errores_caja.dart';

/// Caja del día de una tienda; agrupa sus movimientos de dinero. Su id se forma
/// con la tienda y la fecha (DA-62, DI-21). El saldo esperado se calcula de los
/// movimientos y no se guarda (DA-48).
///
/// Abre con una [getBaseApertura]: el efectivo que había al terminar el día
/// anterior (DI-38). El saldo esperado es esa base más los movimientos.
///
/// Se cierra una vez al día con [cerrar] (CUS-14): guarda lo que se contó, la
/// diferencia con el saldo esperado y el instante del cierre; desde entonces
/// rechaza nuevos movimientos. `recalcularDiferencia` llega con CUS-23.
class Caja {
  /// [baseApertura] es el efectivo con el que abre (cero si no se dice).
  /// [movimientos] y los datos del cierre ([efectivoContado], [diferencia] y
  /// [fechaCierre], los tres juntos) sirven para armar una caja que ya estaba
  /// guardada; no están en EA (DI-37). Con ellos, la caja nace cerrada.
  Caja(
    this._id,
    this._fecha, {
    Decimal? baseApertura,
    List<MovimientoCaja> movimientos = const [],
    this._efectivoContado,
    this._diferencia,
    this._fechaCierre,
  }) : _baseApertura = baseApertura ?? Decimal.zero,
       _cerrada = _efectivoContado != null {
    _movimientos.addAll(movimientos);
  }

  final String _id;
  final DateTime _fecha;
  final Decimal _baseApertura;
  final List<MovimientoCaja> _movimientos = [];
  bool _cerrada;
  Decimal? _efectivoContado;
  Decimal? _diferencia;
  DateTime? _fechaCierre;

  /// Identificador: tienda y fecha (DA-62).
  String getId() => _id;

  /// Día de la caja (fecha local, sin hora; DI-21).
  DateTime getFecha() => _fecha;

  /// Efectivo con el que abrió la caja (DI-38).
  Decimal getBaseApertura() => _baseApertura;

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

  /// Information Expert: la base de apertura más los ingresos menos los
  /// egresos (DA-48, DA-62, DI-38).
  Decimal calcularSaldoEsperado() => _movimientos.fold(
    _baseApertura,
    (saldo, m) => m.esIngreso() ? saldo + m.getValor() : saldo - m.getValor(),
  );

  /// Information Expert: de dónde sale el saldo esperado, por clase de
  /// movimiento (DI-38).
  DesgloseCaja calcularDesglose() {
    var ingresosNegocio = Decimal.zero;
    var ingresosPersonales = Decimal.zero;
    var egresosNegocio = Decimal.zero;
    var cantidadEgresosNegocio = 0;
    var egresosPersonales = Decimal.zero;
    var devoluciones = Decimal.zero;
    for (final m in _movimientos) {
      final valor = m.getValor();
      switch ((m.getClasificacion(), m.esIngreso())) {
        case (ClasificacionMovimiento.negocio, true):
          ingresosNegocio += valor;
        case (ClasificacionMovimiento.negocio, false):
          egresosNegocio += valor;
          cantidadEgresosNegocio++;
        case (ClasificacionMovimiento.personal, true):
          ingresosPersonales += valor;
        case (ClasificacionMovimiento.personal, false):
          egresosPersonales += valor;
        case (ClasificacionMovimiento.anulacion, true):
          devoluciones -= valor;
        case (ClasificacionMovimiento.anulacion, false):
          devoluciones += valor;
      }
    }
    return DesgloseCaja(
      baseApertura: _baseApertura,
      ingresosNegocio: ingresosNegocio,
      ingresosPersonales: ingresosPersonales,
      egresosNegocio: egresosNegocio,
      cantidadEgresosNegocio: cantidadEgresosNegocio,
      egresosPersonales: egresosPersonales,
      devolucionesPorAnulacion: devoluciones,
      saldoEsperado: calcularSaldoEsperado(),
    );
  }

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
