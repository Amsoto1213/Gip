import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/pagos/anulacion_venta.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';

/// Venta del mostrador con sus formas de pago; se crea al confirmar (DA-27).
/// Sus salidas de inventario (`SalidaVenta`) son partes de la venta: la
/// navegación va de la salida a la venta (DA-60).
///
/// Se anula una vez con [anular] (CUS-20): la venta no se borra ni cambia sus
/// datos, solo guarda su [AnulacionVenta] (RNF-15).
class Venta {
  /// [anulacion] sirve para armar una venta ya guardada que fue anulada; no
  /// está en EA (DI-39).
  Venta(
    this._id,
    List<FormaPago> formasPago,
    this._total,
    this._fecha, {
    this._anulacion,
  }) : _formasPago = List.unmodifiable(formasPago);

  final String _id;
  final List<FormaPago> _formasPago;
  final Decimal _total;
  final DateTime _fecha;
  AnulacionVenta? _anulacion;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  List<FormaPago> getFormasPago() => _formasPago;

  /// Total de la venta; lo calcula ServicioVentas.calcularTotal.
  Decimal getTotal() => _total;

  DateTime getFecha() => _fecha;

  /// Information Expert: rechaza si ya está anulada; si no, guarda la
  /// anulación. La venta no se borra (RNF-15).
  void anular(AnulacionVenta anulacion) {
    if (_anulacion != null) throw const ExcepcionVentaYaAnulada();
    _anulacion = anulacion;
  }

  /// Verdadero si tiene anulación.
  bool isAnulada() => _anulacion != null;

  /// Anulación de la venta, o null si está vigente.
  AnulacionVenta? getAnulacion() => _anulacion;
}
