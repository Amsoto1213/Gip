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
