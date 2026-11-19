import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Errores de la exportación de datos (CUS-16).

/// El periodo empieza después de terminar (CUS-16, paso 6).
class ExcepcionPeriodoNoValido extends ExcepcionNegocio {
  const ExcepcionPeriodoNoValido() : super('Periodo no válido');
}
