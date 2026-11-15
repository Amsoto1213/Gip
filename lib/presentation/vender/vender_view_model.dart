import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_venta_perdida_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_venta_coordinator.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Estado de la pantalla Vender (CUS-02, mockup `Main`). Llama a
/// [RegistrarVentaCoordinator] y, para "Anotar que se fue sin él" (CUS-13), a
/// [RegistrarVentaPerdidaCoordinator]: en EA la `VistaVenta` llama a ambos
/// (excepción a un coordinador por view model, DI-30).
///
/// Conserva las líneas de la venta en curso (DA-57): no se guardan hasta
/// confirmar en Cobrar. Quitar una línea y vaciar la venta no tienen reglas de
/// negocio: solo cambian la lista de la pantalla (DI-21).
class VenderViewModel extends ChangeNotifier {
  VenderViewModel(this._coordinator, this._coordinadorPerdida, this._tienda);

  static const mensajeVentaRegistrada = 'Venta registrada';
  static const mensajeVentaPerdida = 'Venta perdida registrada';
  static const mensajeErrorVentaPerdida =
      'No se pudo anotar la venta perdida. Intente de nuevo';
  static const mensajeErrorAgregar =
      'No se pudo agregar el producto. Intente de nuevo';

  final RegistrarVentaCoordinator _coordinator;
  final RegistrarVentaPerdidaCoordinator _coordinadorPerdida;
  final Tienda _tienda;

  final List<LineaVenta> _lineas = [];
  Decimal _total = Decimal.zero;
  String? _error;
  String? _aviso;
  bool _ocupado = false;

  /// Producto que se quiso agregar sin existencia; mientras no sea null se
  /// ofrece anotar la venta perdida.
  Producto? _productoSinExistencia;

  List<LineaVenta> get lineas => List.unmodifiable(_lineas);
  Decimal get total => _total;
  bool get hayLineas => _lineas.isNotEmpty;

  /// Mensaje de error para el tendero, o null.
  String? get error => _error;

  /// Producto sin existencia cuyo botón "Anotar que se fue sin él" está
  /// disponible, o null.
  Producto? get productoSinExistencia => _productoSinExistencia;

  /// "Venta registrada" o "Venta perdida registrada", o null.
  String? get aviso => _aviso;

  /// Agrega una unidad del producto elegido en Buscar (pasos 1 a 28). Si ya
  /// está en la venta, suma uno a su línea.
  Future<void> agregar(Producto producto) => _intentar(
    () => _coordinator.agregarProducto(_tienda, _lineas, producto, Decimal.one),
    mensajeErrorAgregar,
    sinExistencia: producto,
  );

  /// "Anotar que se fue sin él" (CUS-13, pasos 1 a 8): guarda la venta
  /// perdida del producto sin existencia y avisa. La venta en curso no cambia.
  Future<void> registrarVentaPerdida() async {
    final producto = _productoSinExistencia;
    if (producto == null || _ocupado) return;
    _ocupado = true;
    _error = null;
    _aviso = null;
    try {
      await _coordinadorPerdida.registrarVentaPerdida(_tienda, producto);
      _productoSinExistencia = null;
      _aviso = mensajeVentaPerdida;
    } on ExcepcionNegocio catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = mensajeErrorVentaPerdida;
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  /// Botón "+" de la línea.
  Future<void> sumar(LineaVenta linea) => _intentar(
    () async =>
        _coordinator.cambiarCantidad(linea, linea.getCantidad() + Decimal.one),
    mensajeErrorAgregar,
    sinExistencia: linea.getItem().getProducto(),
  );

  /// Botón "−" de la línea; si la cantidad llega a cero, quita la línea.
  Future<void> restar(LineaVenta linea) {
    final nueva = linea.getCantidad() - Decimal.one;
    if (nueva <= Decimal.zero) {
      _lineas.remove(linea);
      return _intentar(() async {}, mensajeErrorAgregar);
    }
    return _intentar(
      () async => _coordinator.cambiarCantidad(linea, nueva),
      mensajeErrorAgregar,
    );
  }

  /// "Vaciar": descarta la venta en curso; no se había guardado nada.
  void vaciar() {
    _lineas.clear();
    _total = Decimal.zero;
    _error = null;
    _aviso = null;
    _productoSinExistencia = null;
    notifyListeners();
  }

  /// Cobrar confirmó la venta: queda en blanco para la siguiente.
  void ventaRegistrada() {
    vaciar();
    _aviso = mensajeVentaRegistrada;
    notifyListeners();
  }

  /// Ya se mostró el aviso o el error.
  void limpiarMensajes() {
    _error = null;
    _aviso = null;
    _productoSinExistencia = null;
  }

  Future<void> _intentar(
    Future<void> Function() accion,
    String mensajeGenerico, {
    Producto? sinExistencia,
  }) async {
    if (_ocupado) return;
    _ocupado = true;
    _error = null;
    _aviso = null;
    _productoSinExistencia = null;
    try {
      await accion();
    } on ExcepcionExistenciaInsuficiente catch (e) {
      _error = e.mensaje;
      _productoSinExistencia = sinExistencia;
    } on ExcepcionNegocio catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = mensajeGenerico;
    } finally {
      _total = _coordinator.obtenerTotal(_lineas);
      _ocupado = false;
      notifyListeners();
    }
  }
}
