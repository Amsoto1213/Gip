/// Registro de la anulación de una venta: quién, cuándo y por qué (RNF-15).
/// Solo se agrega: la venta no se borra ni cambia sus datos (DA-48, DA-51).
///
/// De quien anuló guarda solo el id y el nombre; se los pasa
/// `ServicioVentas.anular` o el repositorio al leerla (DI-61).
class AnulacionVenta {
  AnulacionVenta(
    this._id,
    this._usuarioId,
    this._usuarioNombre,
    this._fecha,
    this._motivo,
  );

  final String _id;
  final String _usuarioId;
  final String _usuarioNombre;
  final DateTime _fecha;
  final String _motivo;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  /// Id del propietario que anuló la venta (RNF-15).
  String getUsuarioId() => _usuarioId;

  /// Nombre del propietario que anuló la venta (RNF-15).
  String getUsuarioNombre() => _usuarioNombre;

  /// Fecha y hora de la anulación, en UTC (RNF-15).
  DateTime getFecha() => _fecha;

  /// Motivo que escribió el propietario.
  String getMotivo() => _motivo;
}
