import 'package:decimal/decimal.dart';

/// Resultado del reporte diario (RF-09, RF-10, IE-08): ventas (y cuánto quedó
/// fiado), abonos, entradas, gastos, utilidad y retiros personales aparte. No se
/// guarda: se genera cada vez (DA-40).
class ReporteDiario {
  ReporteDiario(
    this._fecha,
    this._totalVentas,
    this._ventasFiadas,
    this._ventasNequi,
    this._abonosRecibidos,
    this._abonosNequi,
    this._totalEntradas,
    this._gastosNegocio,
    this._utilidad,
    this._retirosPersonales,
    this._incompleto,
    this._parcial,
  );

  final DateTime _fecha;
  final Decimal _totalVentas;
  final Decimal _ventasFiadas;
  final Decimal _ventasNequi;
  final Decimal _abonosRecibidos;
  final Decimal _abonosNequi;
  final Decimal _totalEntradas;
  final Decimal _gastosNegocio;
  final Decimal _utilidad;
  final Decimal _retirosPersonales;
  final bool _incompleto;
  final bool _parcial;

  DateTime getFecha() => _fecha;

  /// Total vendido, sin ventas anuladas.
  Decimal getTotalVentas() => _totalVentas;

  /// Parte de las ventas que quedó fiada.
  Decimal getVentasFiadas() => _ventasFiadas;

  /// Parte de las ventas pagada por Nequi.
  Decimal getVentasNequi() => _ventasNequi;

  Decimal getAbonosRecibidos() => _abonosRecibidos;

  /// Parte de los abonos que llegó por Nequi.
  Decimal getAbonosNequi() => _abonosNequi;

  /// Information Expert: ventasNequi + abonosNequi, todo el dinero que entró
  /// por Nequi en el día, para cruzarlo con la app de Nequi (DA-63, DA-64).
  Decimal calcularDineroNequi() => _ventasNequi + _abonosNequi;

  Decimal getTotalEntradas() => _totalEntradas;

  Decimal getGastosNegocio() => _gastosNegocio;

  /// Margen de las salidas vigentes del día menos los gastos del negocio; no
  /// resta retiros personales ni devoluciones por anulación.
  Decimal getUtilidad() => _utilidad;

  /// Columna aparte de retiros personales (RF-10).
  Decimal getRetirosPersonales() => _retirosPersonales;

  /// Verdadero si la utilidad no es exacta porque falta algún costo.
  bool isIncompleto() => _incompleto;

  /// Verdadero si hay operaciones sin subir al servidor (ERS 3.2.5).
  bool isParcial() => _parcial;
}
