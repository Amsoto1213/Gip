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

/// Cliente nuevo sin nombre (CUS-07, pasos 4 a 6).
class ExcepcionNombreClienteObligatorio extends ExcepcionNegocio {
  const ExcepcionNombreClienteObligatorio()
    : super('El nombre del cliente es obligatorio');
}

/// Fiado con monto cero o negativo (CUS-07, pasos 14 a 16; IE-06).
class ExcepcionMontoFiadoNoValido extends ExcepcionNegocio {
  const ExcepcionMontoFiadoNoValido()
    : super('El monto del fiado debe ser mayor que cero');
}

/// Abono con monto cero, negativo o mayor que el saldo pendiente (CUS-08,
/// pasos 6 a 8; IE-06).
class ExcepcionMontoAbonoNoValido extends ExcepcionNegocio {
  const ExcepcionMontoAbonoNoValido()
    : super(
        'El abono debe ser mayor que cero y no puede superar el saldo '
        'pendiente',
      );
}

/// Eliminar los datos de un cliente que aún debe (CUS-21, pasos 8 a 10).
class ExcepcionClienteConSaldo extends ExcepcionNegocio {
  const ExcepcionClienteConSaldo()
    : super('No se pueden eliminar los datos: el cliente aún debe');
}

/// Anular una venta que ya estaba anulada (CUS-20, pasos 20 a 22).
class ExcepcionVentaYaAnulada extends ExcepcionNegocio {
  const ExcepcionVentaYaAnulada() : super('La venta ya estaba anulada');
}

/// Anular una venta sin escribir el motivo (CUS-20; la pantalla lo pide
/// obligatorio, DI-39).
class ExcepcionMotivoAnulacionObligatorio extends ExcepcionNegocio {
  const ExcepcionMotivoAnulacionObligatorio()
    : super('Escribe el motivo de la anulación');
}

/// Anular un fiado que ya tiene abonos (CUS-20, paso 35): la venta no se puede
/// anular.
class ExcepcionFiadoConAbonos extends ExcepcionNegocio {
  const ExcepcionFiadoConAbonos()
    : super('No se puede anular la venta: el fiado ya tiene abonos');
}
