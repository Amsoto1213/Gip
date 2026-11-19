import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Errores de la caja.

/// La caja del día ya se cerró: no recibe más movimientos (Caja).
class ExcepcionCajaCerrada extends ExcepcionNegocio {
  const ExcepcionCajaCerrada() : super('La caja de hoy ya está cerrada');
}

/// Se pidió recalcular la diferencia de una caja que no está cerrada
/// (CUS-22, DI-45).
class ExcepcionCajaNoCerrada extends ExcepcionNegocio {
  const ExcepcionCajaNoCerrada()
    : super('La caja todavía no se ha cerrado: no hay diferencia que revisar');
}

/// Un movimiento de caja con valor cero o negativo (ServicioCaja).
class ExcepcionValorMovimientoNoValido extends ExcepcionNegocio {
  const ExcepcionValorMovimientoNoValido()
    : super('El valor debe ser mayor que cero');
}

/// El propietario intentó anotar a mano un movimiento ANULACION, que solo
/// registra la anulación de ventas (CUS-11, pasos 5 a 8; DA-51).
class ExcepcionClasificacionNoPermitida extends ExcepcionNegocio {
  const ExcepcionClasificacionNoPermitida()
    : super('Esa clasificación solo la usa la anulación de ventas');
}
