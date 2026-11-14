import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/gestionar_producto_coordinator.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Estado de la pantalla Producto (CUS-18). Llama solo a
/// [GestionarProductoCoordinator].
///
/// Sin [producto] la pantalla crea uno nuevo; con él, lo edita. Después de
/// "Producto creado" queda en modo edición sobre el producto recién creado
/// (DI-16).
class ProductoViewModel extends ChangeNotifier {
  ProductoViewModel(this._coordinator, this._tienda, {this._producto});

  final GestionarProductoCoordinator _coordinator;
  final Tienda _tienda;
  Producto? _producto;

  bool _guardando = false;
  String? _error;
  String? _aviso;

  /// Producto que se está editando, o null si es uno nuevo.
  Producto? get producto => _producto;
  bool get esNuevo => _producto == null;
  bool get guardando => _guardando;

  /// Mensaje de error para el tendero, o null.
  String? get error => _error;

  /// "Producto creado" o "Producto actualizado", o null.
  String? get aviso => _aviso;

  /// Crea o edita según el modo. Los precios llegan como los escribió el
  /// tendero (p. ej. "3.500" o "2.600,50"); el costo vacío queda nulo.
  Future<void> guardar({
    required String codigo,
    required String nombre,
    required UnidadMedida unidad,
    required String precioVenta,
    required String precioCompra,
  }) async {
    if (_guardando) return;
    _error = null;
    _aviso = null;

    final venta = leerPrecio(precioVenta);
    if (venta == null) {
      _error = 'Escribe el precio de venta';
      notifyListeners();
      return;
    }
    final compraVacia = precioCompra.trim().isEmpty;
    final compra = compraVacia ? null : leerPrecio(precioCompra);
    if (!compraVacia && compra == null) {
      _error = 'Escribe un costo válido o déjalo vacío';
      notifyListeners();
      return;
    }

    _guardando = true;
    notifyListeners();
    try {
      final actual = _producto;
      if (actual == null) {
        _producto = await _coordinator.crearProducto(
          _tienda,
          codigo,
          nombre,
          unidad,
          compra,
          venta,
        );
        _aviso = 'Producto creado';
      } else {
        await _coordinator.editarProducto(
          _tienda,
          actual,
          nombre,
          unidad,
          compra,
          venta,
        );
        _aviso = 'Producto actualizado';
      }
    } on ExcepcionNegocio catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = 'No se pudo guardar el producto. Inténtalo de nuevo';
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  /// Convierte un precio escrito en pesos colombianos (ver [leerPesos]).
  static Decimal? leerPrecio(String texto) => leerPesos(texto);
}
