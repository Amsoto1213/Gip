import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/info_tienda/formato_exportacion.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

/// Datos del negocio que se exportan (CUS-16, RNF-22): inventario con su
/// stock, ventas del periodo y fiados con sus abonos. No se guarda: la arma
/// `ServicioExportacion` y la recibe `IExportador` (DA-68).
class DatosExportacion {
  DatosExportacion(
    this._fecha,
    this._desde,
    this._hasta,
    this._formato,
    List<ItemInventario> items,
    List<Venta> ventas,
    List<Fiado> fiados,
  ) : _items = List.unmodifiable(items),
      _ventas = List.unmodifiable(ventas),
      _fiados = List.unmodifiable(fiados);

  final DateTime _fecha;
  final DateTime _desde;
  final DateTime _hasta;
  final FormatoExportacion _formato;
  final List<ItemInventario> _items;
  final List<Venta> _ventas;
  final List<Fiado> _fiados;

  /// Fecha y hora en que se generó.
  DateTime getFecha() => _fecha;

  /// Inicio del periodo de las ventas (incluido).
  DateTime getDesde() => _desde;

  /// Fin del periodo de las ventas (no incluido, como en DI-28).
  DateTime getHasta() => _hasta;

  /// CSV o EXCEL.
  FormatoExportacion getFormato() => _formato;

  /// Inventario: cada ítem con su producto y su stock.
  List<ItemInventario> getItems() => _items;

  /// Ventas del periodo con sus formas de pago y su anulación, si la tienen.
  List<Venta> getVentas() => _ventas;

  /// Fiados de la tienda con sus abonos.
  List<Fiado> getFiados() => _fiados;
}
