import 'package:gip/business/entidades/info_tienda/usuario.dart';

/// Registro de la anulación de una venta: quién, cuándo y por qué (RNF-15).
/// Solo se agrega: la venta no se borra ni cambia sus datos (DA-48, DA-51).
class AnulacionVenta {
  AnulacionVenta(this._id, this._usuario, this._fecha, this._motivo);

  final String _id;
  final Usuario _usuario;
  final DateTime _fecha;
  final String _motivo;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  /// Propietario que anuló la venta (RNF-15).
  Usuario getUsuario() => _usuario;

  /// Fecha y hora de la anulación, en UTC (RNF-15).
  DateTime getFecha() => _fecha;

  /// Motivo que escribió el propietario.
  String getMotivo() => _motivo;
}
