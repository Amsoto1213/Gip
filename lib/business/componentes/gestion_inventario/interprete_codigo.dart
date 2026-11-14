import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Polymorphism y Protected Variations: cada tipo de código se interpreta
/// distinto (RF-06, DA-47). Las implementaciones llegan con CUS-17 (DI-15).
abstract interface class InterpreteCodigo {
  /// Indica si la lectura tiene el formato que este intérprete entiende.
  bool reconoce(String lectura);

  /// Producto asociado a la lectura, o null si no existe.
  Future<Producto?> buscar(Tienda tienda, String lectura);

  /// Deduce el formato del texto leído (DA-47).
  FormatoCodigo formatoDe(String lectura);
}
