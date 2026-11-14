/// Identifica la tienda; los repositorios la reciben como parámetro para aislar
/// los datos (RNF-13, DA-28). Ningún caso de uso la edita (DA-65).
/// [id] es el `tienda_id` de todas las tablas (DI-11).
class Tienda {
  Tienda(this._id, this._codigo, this._nombre, this._direccion);

  final String _id;
  final String _codigo;
  final String _nombre;
  final String _direccion;

  /// Uuid de la tienda; es el `tienda_id` de todas las tablas (DI-11).
  String getId() => _id;

  /// Código de la tienda (RNF-13).
  String getCodigo() => _codigo;

  String getNombre() => _nombre;

  String getDireccion() => _direccion;
}
