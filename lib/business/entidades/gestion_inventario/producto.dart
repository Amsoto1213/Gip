import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';

/// Producto del catálogo con sus precios y sus códigos (de barras o QR); su
/// stock está en `ItemInventario` (DA-19). Se identifica por id; [getCodigo] es
/// el código interno que pone la tienda y no se repite dentro de ella (DA-59).
class Producto {
  /// [actualizadoEn] arranca con la hora actual en UTC; al leer de la base se
  /// asigna con [setActualizadoEn].
  Producto(
    this._id,
    this._codigo,
    this._nombre,
    this._unidadMedida,
    this._precioCompra,
    this._precioVenta,
  ) : _actualizadoEn = DateTime.now().toUtc();

  final String _id;
  final String _codigo;
  String _nombre;
  UnidadMedida _unidadMedida;
  Decimal? _precioCompra;
  Decimal _precioVenta;
  final List<CodigoProducto> _codigos = [];
  DateTime _actualizadoEn;

  /// Identificador único del objeto (DA-43).
  String getId() => _id;

  /// Código interno de la tienda; no se edita (DA-59).
  String getCodigo() => _codigo;

  String getNombre() => _nombre;

  UnidadMedida getUnidadMedida() => _unidadMedida;

  /// Precio de compra; nulo si la tienda no lo conoce: los márgenes de este
  /// producto quedan como dato incompleto (ERS 3.2.4).
  Decimal? getPrecioCompra() => _precioCompra;

  Decimal getPrecioVenta() => _precioVenta;

  List<CodigoProducto> getCodigos() => List.unmodifiable(_codigos);

  /// Fecha de la última edición; al sincronizar gana la más reciente (DA-48).
  DateTime getActualizadoEn() => _actualizadoEn;

  void setNombre(String nombre) => _nombre = nombre;

  void setUnidadMedida(UnidadMedida unidadMedida) =>
      _unidadMedida = unidadMedida;

  void setPrecioCompra(Decimal? precioCompra) => _precioCompra = precioCompra;

  void setPrecioVenta(Decimal precioVenta) => _precioVenta = precioVenta;

  /// La asigna el servicio al editar (DA-48). Siempre se guarda en UTC.
  void setActualizadoEn(DateTime actualizadoEn) =>
      _actualizadoEn = actualizadoEn.toUtc();

  void agregarCodigo(CodigoProducto codigo) => _codigos.add(codigo);

  /// Quita el código de su lista. Lo usa la resolución de un CODIGO_REPETIDO
  /// (DA-66).
  void quitarCodigo(CodigoProducto codigo) =>
      _codigos.removeWhere((c) => c.getId() == codigo.getId());
}
