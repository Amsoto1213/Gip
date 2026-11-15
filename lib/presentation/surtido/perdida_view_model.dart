import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_perdida_coordinator.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Estado de la pantalla Pérdida o devolución (CUS-03). Llama solo a
/// [RegistrarPerdidaCoordinator].
///
/// El producto llega de Buscar producto (CUS-06). Al elegirlo pide la
/// existencia con `consultarExistencia` para mostrar "Hay N" y "Quedará en"
/// (DI-22). No deja confirmar sin producto ni sin motivo (IE-03); las reglas
/// de cantidad y existencia las aplica el servicio.
class PerdidaViewModel extends ChangeNotifier {
  PerdidaViewModel(this._coordinator, this._tienda);

  /// Mensaje del diagrama (paso 22) para un error que no es de negocio.
  static const mensajeErrorGuardar =
      'No se pudo registrar la pérdida. Intente de nuevo';
  static const mensajeSinCantidad = 'Escriba cuántas salen del surtido';
  static const mensajeSoloEnteros =
      'Este producto se vende por unidad: escriba un número entero';

  final RegistrarPerdidaCoordinator _coordinator;
  final Tienda _tienda;

  Producto? _producto;
  Decimal? _existencia;
  String _textoCantidad = '';
  Decimal? _cantidad;
  MotivoMerma? _motivo;
  bool _registrando = false;
  String? _error;
  String? _aviso;
  int _ultimaConsulta = 0;
  bool _cerrado = false;

  Producto? get producto => _producto;

  /// Existencia actual del producto, o null mientras no se conoce.
  Decimal? get existencia => _existencia;

  /// Cantidad escrita, o null si no es un número válido para la unidad.
  Decimal? get cantidad => _cantidad;

  MotivoMerma? get motivo => _motivo;

  bool get registrando => _registrando;

  /// Mensaje de error para el tendero, o null.
  String? get error => _error;

  /// "Pérdida registrada. Nuevo stock: N", o null.
  String? get aviso => _aviso;

  /// Kilos y libras admiten decimales; la unidad, no (IE-01 b).
  bool get admiteDecimales =>
      _producto != null && _producto!.getUnidadMedida() != UnidadMedida.unidad;

  /// Existencia menos la cantidad escrita, o null si falta alguna o quedaría
  /// negativa (el servicio lo rechaza al confirmar).
  Decimal? get quedaraEn {
    final existencia = _existencia;
    final cantidad = _cantidad;
    if (existencia == null || cantidad == null) return null;
    final resto = existencia - cantidad;
    return resto < Decimal.zero ? null : resto;
  }

  /// La pantalla no deja confirmar sin producto ni sin motivo (IE-03).
  bool get puedeConfirmar =>
      _producto != null && _motivo != null && !_registrando;

  /// Producto elegido en Buscar producto: consulta su existencia.
  Future<void> elegirProducto(Producto producto) async {
    _producto = producto;
    _existencia = null;
    _aviso = null;
    _error = null;
    _cantidad = _leer(_textoCantidad);
    notifyListeners();
    await _consultarExistencia();
  }

  /// Cantidad como la escribe el tendero; acepta coma o punto decimal en kilos
  /// y libras ("2,5").
  void cambiarCantidad(String texto) {
    _textoCantidad = texto;
    _cantidad = _leer(texto);
    _aviso = null;
    _error = _cantidad == null && _esFraccionEnUnidades(texto)
        ? mensajeSoloEnteros
        : null;
    notifyListeners();
  }

  /// Suma [paso] a la cantidad (botones − y +); no baja de cero. Devuelve la
  /// nueva cantidad para que la vista actualice el campo.
  Decimal sumarCantidad(Decimal paso) {
    final nueva = (_cantidad ?? Decimal.zero) + paso;
    _cantidad = nueva < Decimal.zero ? Decimal.zero : nueva;
    _textoCantidad = _cantidad.toString();
    _aviso = null;
    _error = null;
    notifyListeners();
    return _cantidad!;
  }

  void elegirMotivo(MotivoMerma motivo) {
    _motivo = motivo;
    _aviso = null;
    notifyListeners();
  }

  /// registrarPerdida del coordinador. Devuelve verdadero si quedó registrada,
  /// para que la vista limpie la cantidad.
  Future<bool> registrar() async {
    final producto = _producto;
    if (!puedeConfirmar || producto == null) return false;
    _error = null;
    _aviso = null;
    final cantidad = _cantidad;
    if (cantidad == null) {
      _error = _esFraccionEnUnidades(_textoCantidad)
          ? mensajeSoloEnteros
          : mensajeSinCantidad;
      notifyListeners();
      return false;
    }

    _registrando = true;
    notifyListeners();
    try {
      final merma = await _coordinator.registrarPerdida(
        _tienda,
        producto,
        cantidad,
        _motivo,
      );
      final nuevoStock = merma.getItem().getStockActual();
      _existencia = nuevoStock;
      _aviso = 'Pérdida registrada. Nuevo stock: ${mostrarPrecio(nuevoStock)}';
      _cantidad = null;
      _textoCantidad = '';
      _motivo = null;
      return true;
    } on ExcepcionCantidadSuperaExistencia catch (e) {
      _error = e.mensaje;
      // La existencia mostrada pudo cambiar (una venta mientras tanto).
      unawaited(_consultarExistencia());
      return false;
    } on ExcepcionNegocio catch (e) {
      _error = e.mensaje;
      return false;
    } catch (_) {
      _error = mensajeErrorGuardar;
      return false;
    } finally {
      _registrando = false;
      if (!_cerrado) notifyListeners();
    }
  }

  /// consultarExistencia del coordinador; descarta la respuesta de una
  /// consulta vieja.
  Future<void> _consultarExistencia() async {
    final producto = _producto;
    if (producto == null) return;
    final consulta = ++_ultimaConsulta;
    try {
      final existencia = await _coordinator.consultarExistencia(
        _tienda,
        producto,
      );
      if (_cerrado || consulta != _ultimaConsulta) return;
      _existencia = existencia;
    } on ExcepcionNegocio catch (e) {
      if (_cerrado || consulta != _ultimaConsulta) return;
      _error = e.mensaje;
    } catch (_) {
      // "Hay N" es informativo: si no se puede leer, no se muestra.
      if (_cerrado || consulta != _ultimaConsulta) return;
    }
    notifyListeners();
  }

  /// Número escrito, sin separador de miles; coma o punto decimal. Null si no
  /// es un número o si tiene decimales y el producto se vende por unidad.
  Decimal? _leer(String texto) {
    final valor = leerCantidad(texto);
    if (valor == null) return null;
    if (_producto != null && !admiteDecimales && !valor.isInteger) {
      return null;
    }
    return valor;
  }

  bool _esFraccionEnUnidades(String texto) {
    final valor = leerCantidad(texto);
    return _producto != null &&
        valor != null &&
        !admiteDecimales &&
        !valor.isInteger;
  }

  /// Cantidad escrita: sin separador de miles; la coma o el punto son
  /// decimales. Devuelve null si no es un número.
  static Decimal? leerCantidad(String texto) {
    final limpio = texto.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
    if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(limpio)) return null;
    return Decimal.parse(limpio);
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
