import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Errores de la caja.

/// La caja del día ya se cerró: no recibe más movimientos (Caja).
class ExcepcionCajaCerrada extends ExcepcionNegocio {
  const ExcepcionCajaCerrada() : super('La caja del día ya está cerrada');
}

/// Un movimiento de caja con valor cero o negativo (ServicioCaja).
class ExcepcionValorMovimientoNoValido extends ExcepcionNegocio {
  const ExcepcionValorMovimientoNoValido()
    : super('El valor debe ser mayor que cero');
}
