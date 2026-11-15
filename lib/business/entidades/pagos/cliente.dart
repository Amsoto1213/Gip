import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';

/// Cliente de la tienda que puede tener fiados; solo nombre y teléfono
/// (RNF-16). No se edita: se registra y se elimina cuando ya no debe (DA-59).
/// El teléfono vacío ('') significa que no lo dio (DI-26).
///
/// `obtenerHistorial` llega con CUS-19 completo.
class Cliente {
  Cliente(this._id, this._nombre, this._telefono);

  final String _id;
  final String _nombre;
  final String _telefono;
  final List<Fiado> _fiados = [];

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  String getNombre() => _nombre;

  /// Teléfono, o '' si no lo dio.
  String getTelefono() => _telefono;

  /// Information Expert: fiados en estado PENDIENTE (CUR-07, CUR-08).
  List<Fiado> obtenerFiadosPendientes() => List.unmodifiable(
    _fiados.where((f) => f.getEstado() == EstadoFiado.pendiente),
  );

  /// Information Expert: suma del saldo de cada fiado pendiente (CUS-19).
  Decimal calcularSaldoPendiente() => obtenerFiadosPendientes().fold(
    Decimal.zero,
    (s, f) => s + f.getSaldoPendiente(),
  );

  /// Information Expert: verdadero si no tiene fiados pendientes (CUS-21,
  /// DA-69).
  bool puedeEliminarse() => obtenerFiadosPendientes().isEmpty;

  /// Agrega el fiado a su lista; así la lista no se modifica desde afuera.
  void agregarFiado(Fiado fiado) => _fiados.add(fiado);
}
