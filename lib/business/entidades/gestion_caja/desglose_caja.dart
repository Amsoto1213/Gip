import 'package:decimal/decimal.dart';

/// De dónde sale el saldo esperado de una caja: la base con la que abrió y lo
/// que entró y salió, por clase de movimiento. Se calcula de los movimientos y
/// no se guarda (DA-48, DI-38).
///
/// Siempre cumple: `saldoEsperado = baseApertura + ingresosNegocio +
/// ingresosPersonales − egresosNegocio − egresosPersonales −
/// devolucionesPorAnulacion`.
class DesgloseCaja {
  const DesgloseCaja({
    required this.baseApertura,
    required this.ingresosNegocio,
    required this.ingresosPersonales,
    required this.egresosNegocio,
    required this.cantidadEgresosNegocio,
    required this.egresosPersonales,
    required this.devolucionesPorAnulacion,
    required this.saldoEsperado,
  });

  /// Efectivo con el que abrió la caja de hoy (lo contado en el último cierre).
  final Decimal baseApertura;

  /// Ventas de contado, abonos en efectivo y otros ingresos del negocio.
  final Decimal ingresosNegocio;

  /// Dinero personal que se puso en la caja ("Entra dinero" · Personal).
  final Decimal ingresosPersonales;

  /// Gastos del negocio.
  final Decimal egresosNegocio;

  /// Cuántos movimientos suman [egresosNegocio].
  final int cantidadEgresosNegocio;

  /// Retiros personales: lo que sale para la casa, aparte de la ganancia.
  final Decimal egresosPersonales;

  /// Dinero devuelto por ventas anuladas. Neto: lo que sale menos lo que entra
  /// con esa clasificación.
  final Decimal devolucionesPorAnulacion;

  final Decimal saldoEsperado;
}
