import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Errores del surtido: catálogo e inventario.

/// Datos de un producto que no cumplen las reglas de CUS-18: código interno
/// repetido o vacío, nombre vacío o algún precio negativo.
class ExcepcionDatosProductoNoValidos extends ExcepcionNegocio {
  /// Al crear: el código interno puede estar repetido (CUS-18, paso 8).
  const ExcepcionDatosProductoNoValidos.alCrear()
    : super('El código interno ya existe o faltan datos válidos');

  /// Al editar: el código interno no se edita, así que solo pueden faltar datos.
  const ExcepcionDatosProductoNoValidos.alEditar()
    : super('Faltan datos válidos del producto');
}

/// Cantidad <= 0 o costo negativo en una entrada de mercancía (CUS-01, pasos
/// 15 a 17).
class ExcepcionDatosEntradaNoValidos extends ExcepcionNegocio {
  const ExcepcionDatosEntradaNoValidos()
    : super(
        'La cantidad debe ser mayor que cero y el costo no puede ser negativo',
      );
}

/// El producto no tiene ítem de inventario en la tienda (obtenerItem).
class ExcepcionProductoSinInventario extends ExcepcionNegocio {
  const ExcepcionProductoSinInventario()
    : super('El producto no tiene inventario en esta tienda');
}

/// El movimiento dejaría el stock negativo (ERS 3.2.1 a).
class ExcepcionStockNegativo extends ExcepcionNegocio {
  const ExcepcionStockNegativo()
    : super('No hay suficiente existencia del producto');
}

/// Cantidad <= 0 o motivo sin elegir en una pérdida o devolución (CUS-03,
/// pasos 5 a 7).
class ExcepcionDatosMermaNoValidos extends ExcepcionNegocio {
  const ExcepcionDatosMermaNoValidos()
    : super('La cantidad debe ser mayor que cero y el motivo es obligatorio');
}

/// La pérdida o devolución saca más de lo que hay en el surtido (CUS-03, paso
/// 22; DI-22).
class ExcepcionCantidadSuperaExistencia extends ExcepcionNegocio {
  const ExcepcionCantidadSuperaExistencia()
    : super('La cantidad supera la existencia');
}
