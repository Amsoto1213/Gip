import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Errores de las ventas y sus pagos.

/// No hay existencia para la cantidad pedida al agregar o cambiar una línea
/// (RN-01, CUS-02 paso 26). Distinta de `ExcepcionStockNegativo` para que
/// CUS-13 ofrezca anotar la venta perdida.
class ExcepcionExistenciaInsuficiente extends ExcepcionNegocio {
  const ExcepcionExistenciaInsuficiente()
    : super('No hay suficiente existencia del producto');
}

/// Cantidad cero o negativa en una línea de la venta.
class ExcepcionCantidadNoValida extends ExcepcionNegocio {
  const ExcepcionCantidadNoValida()
    : super('La cantidad debe ser mayor que cero');
}

/// El efectivo recibido no cubre lo que falta pagar (CUS-02, paso 32).
class ExcepcionMontoInsuficiente extends ExcepcionNegocio {
  const ExcepcionMontoInsuficiente() : super('El monto recibido no alcanza');
}

/// Un pago con monto cero o negativo (CUS-02, nota del paso 40; DI-21).
class ExcepcionMontoNoValido extends ExcepcionNegocio {
  const ExcepcionMontoNoValido() : super('El monto debe ser mayor que cero');
}

/// Las formas de pago no suman el total, repiten tipo o son más de tres
/// (CUS-02, pasos 52 a 54).
class ExcepcionFormasPagoNoValidas extends ExcepcionNegocio {
  const ExcepcionFormasPagoNoValidas()
    : super('Las formas de pago no cubren el total de la venta');
}
