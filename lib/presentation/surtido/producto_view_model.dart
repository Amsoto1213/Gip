import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/gestionar_producto_coordinator.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/transversal/configuracion/configuracion_inventario.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Estado de la pantalla Producto (CUS-18). Llama solo a
/// [GestionarProductoCoordinator].
///
/// Sin [producto] la pantalla crea uno nuevo; con él, lo edita. Después de
/// "Producto creado" queda en modo edición sobre el producto recién creado
/// (DI-16).
///
/// Códigos de barras o QR (opt "Asociar código"): a un producto guardado se
/// asocian de una vez; a uno nuevo, el código queda pendiente y se asocia al
/// crearlo. [codigoLeido] es el código que se leyó en Buscar producto y no
/// estaba registrado (CUS-17 → CUS-18).
///
/// Etiquetas (opt "Etiquetas"): con un producto guardado se imprimen [copias]
/// etiquetas con su código QR (DI-35).
class ProductoViewModel extends ChangeNotifier {
  ProductoViewModel(
    this._coordinator,
    this._tienda, {
    Producto? producto,
    String? codigoLeido,
  }) : _producto = producto,
       _codigoPendiente = producto == null ? _limpio(codigoLeido) : null;

  final GestionarProductoCoordinator _coordinator;
  final Tienda _tienda;
  Producto? _producto;
  String? _codigoPendiente;

  /// Copias que se proponen al abrir el panel de etiquetas (mockup `wProducto`).
  static const int copiasIniciales = 10;
  static const int copiasMaximas =
      ConfiguracionInventario.maximoCopiasEtiquetas;

  int _copias = copiasIniciales;
  bool _imprimiendo = false;
  bool _guardando = false;
  String? _error;
  String? _aviso;

  static String? _limpio(String? texto) {
    final t = texto?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  /// Producto que se está editando, o null si es uno nuevo.
  Producto? get producto => _producto;
  bool get esNuevo => _producto == null;

  /// Verdadero mientras guarda el producto o asocia un código.
  bool get guardando => _guardando;

  /// Códigos ya asociados al producto, en el orden en que se asociaron.
  List<CodigoProducto> get codigos =>
      _producto?.getCodigos() ?? const <CodigoProducto>[];

  /// Código que se asociará al crear el producto, o null.
  String? get codigoPendiente => _codigoPendiente;

  /// Copias de etiquetas que se imprimirán, entre 1 y [copiasMaximas].
  int get copias => _copias;

  /// Verdadero mientras se arma y se envía la impresión de etiquetas.
  bool get imprimiendo => _imprimiendo;

  /// Cambia las copias; lo que quede fuera de 1 a [copiasMaximas] se ajusta.
  void cambiarCopias(int valor) {
    _copias = valor.clamp(1, copiasMaximas);
    notifyListeners();
  }

  /// Imprime las etiquetas del producto guardado (CUS-18, pasos 41 a 51):
  /// "Etiquetas enviadas a impresión" o el mensaje del rechazo.
  Future<void> imprimirEtiquetas() async {
    final actual = _producto;
    if (_imprimiendo || _guardando || actual == null) return;
    _error = null;
    _aviso = null;
    _imprimiendo = true;
    notifyListeners();
    try {
      await _coordinator.imprimirEtiquetas(_tienda, [actual], _copias);
      _aviso = 'Etiquetas enviadas a impresión';
    } on ExcepcionNegocio catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = 'No se pudo imprimir. Inténtalo de nuevo';
    } finally {
      _imprimiendo = false;
      notifyListeners();
    }
  }

  /// Mensaje de error para el tendero, o null.
  String? get error => _error;

  /// "Producto creado" o "Producto actualizado", o null.
  String? get aviso => _aviso;

  /// Asocia [valor] al producto (CUS-18, pasos 18 a 33): "Código asociado" o
  /// el mensaje del rechazo ("Ese código ya está asociado a otro producto").
  /// Si el producto todavía no se ha creado, el código queda pendiente.
  Future<void> asociarCodigo(String valor) async {
    if (_guardando) return;
    _error = null;
    _aviso = null;
    final actual = _producto;
    if (actual == null) {
      final codigo = _limpio(valor);
      if (codigo == null) {
        _error = const ExcepcionCodigoVacio().mensaje;
      } else {
        _codigoPendiente = codigo;
      }
      notifyListeners();
      return;
    }

    _guardando = true;
    notifyListeners();
    try {
      await _coordinator.asociarCodigo(_tienda, actual, valor);
      _aviso = 'Código asociado';
    } on ExcepcionNegocio catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = 'No se pudo asociar el código. Inténtalo de nuevo';
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  /// Quita el código pendiente de un producto nuevo (no se había guardado).
  void descartarCodigoPendiente() {
    _codigoPendiente = null;
    notifyListeners();
  }

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
        final creado = await _coordinator.crearProducto(
          _tienda,
          codigo,
          nombre,
          unidad,
          compra,
          venta,
        );
        _producto = creado;
        _aviso = 'Producto creado';
        final pendiente = _codigoPendiente;
        if (pendiente != null) {
          _codigoPendiente = null;
          // El producto ya quedó creado: si el código falla, se avisa aparte.
          try {
            await _coordinator.asociarCodigo(_tienda, creado, pendiente);
            _aviso = 'Producto creado. Código asociado';
          } on ExcepcionNegocio catch (e) {
            _error = e.mensaje;
          } catch (_) {
            _error = 'No se pudo asociar el código. Inténtalo de nuevo';
          }
        }
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
