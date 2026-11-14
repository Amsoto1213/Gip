import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_entrada_mercancia_coordinator.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Estado de la pantalla Entrada de mercancía (CUS-01). Llama solo a
/// [RegistrarEntradaMercanciaCoordinator].
///
/// El producto llega de Buscar producto (CUS-06). Cada vez que cambia el costo
/// pregunta al coordinador si difiere de la última entrada (pasos 2 a 11); la
/// advertencia no bloquea. "Existencia actual", "último costo" y "Quedará en"
/// del mockup no se muestran: el diseño no tiene de dónde leerlos (DI-20).
class EntradaMercanciaViewModel extends ChangeNotifier {
  EntradaMercanciaViewModel(this._coordinator, this._tienda);

  /// Mensajes del diagrama de secuencia.
  static const mensajeCostoDistinto =
      'El costo es distinto al de la última entrada';
  static const mensajeErrorGuardar =
      'No se pudo registrar la entrada. Intente de nuevo';

  final RegistrarEntradaMercanciaCoordinator _coordinator;
  final Tienda _tienda;

  Producto? _producto;
  Decimal? _cantidad;
  Decimal? _costo;
  bool _costoDifiere = false;
  bool _registrando = false;
  String? _error;
  String? _aviso;
  int _ultimaVerificacion = 0;
  bool _cerrado = false;

  Producto? get producto => _producto;

  /// Cantidad escrita, o null si no es un número.
  Decimal? get cantidad => _cantidad;

  /// Costo por unidad escrito, o null si no es un número.
  Decimal? get costo => _costo;

  /// Verdadero si hay que mostrar [mensajeCostoDistinto].
  bool get costoDifiere => _costoDifiere;

  bool get registrando => _registrando;

  /// Mensaje de error para el tendero, o null.
  String? get error => _error;

  /// "Entrada registrada. Nuevo stock: ...", o null.
  String? get aviso => _aviso;

  /// Total de la compra que se muestra mientras se escribe (cantidad x costo),
  /// o null si falta alguno. Al registrar, el total es
  /// `EntradaMercancia.calcularCostoTotal`.
  Decimal? get totalCompra {
    final cantidad = _cantidad;
    final costo = _costo;
    return cantidad == null || costo == null ? null : cantidad * costo;
  }

  /// Producto elegido en Buscar producto. Vuelve a verificar el costo escrito.
  Future<void> elegirProducto(Producto producto) async {
    _producto = producto;
    _aviso = null;
    _error = null;
    notifyListeners();
    await _verificarCosto();
  }

  /// Cantidad como la escribe el tendero; acepta coma o punto decimal para
  /// kilos y libras ("2,5").
  void cambiarCantidad(String texto) {
    _cantidad = leerCantidad(texto);
    _aviso = null;
    notifyListeners();
  }

  /// Suma [paso] a la cantidad (botones − y +); no baja de cero.
  Decimal sumarCantidad(Decimal paso) {
    final nueva = (_cantidad ?? Decimal.zero) + paso;
    _cantidad = nueva < Decimal.zero ? Decimal.zero : nueva;
    _aviso = null;
    notifyListeners();
    return _cantidad!;
  }

  /// Costo por unidad en pesos ("9.400"). Pregunta si difiere del histórico.
  Future<void> cambiarCosto(String texto) async {
    _costo = leerPesos(texto);
    _aviso = null;
    notifyListeners();
    await _verificarCosto();
  }

  /// verificarCosto(tienda, producto, costoUnitario) del coordinador. Si una
  /// verificación vieja termina después de una nueva, se descarta.
  Future<void> _verificarCosto() async {
    final verificacion = ++_ultimaVerificacion;
    final producto = _producto;
    final costo = _costo;
    if (producto == null || costo == null || costo < Decimal.zero) {
      if (_costoDifiere) {
        _costoDifiere = false;
        notifyListeners();
      }
      return;
    }
    try {
      final difiere = await _coordinator.verificarCosto(
        _tienda,
        producto,
        costo,
      );
      if (_cerrado || verificacion != _ultimaVerificacion) return;
      _costoDifiere = difiere;
    } on ExcepcionNegocio catch (e) {
      if (_cerrado || verificacion != _ultimaVerificacion) return;
      _costoDifiere = false;
      _error = e.mensaje;
    } catch (_) {
      // La advertencia es opcional: si no se puede verificar, no se muestra.
      if (_cerrado || verificacion != _ultimaVerificacion) return;
      _costoDifiere = false;
    }
    notifyListeners();
  }

  /// registrarEntrada del coordinador. Devuelve verdadero si quedó registrada,
  /// para que la vista limpie el formulario. Un número de factura vacío se
  /// permite.
  Future<bool> registrar(String numeroFactura) async {
    if (_registrando) return false;
    _error = null;
    _aviso = null;

    final producto = _producto;
    if (producto == null) {
      _error = 'Elija el producto que llegó';
      notifyListeners();
      return false;
    }
    final cantidad = _cantidad;
    final costo = _costo;
    if (cantidad == null || costo == null) {
      _error = cantidad == null
          ? 'Escriba cuántas unidades llegaron'
          : 'Escriba el costo por unidad';
      notifyListeners();
      return false;
    }

    _registrando = true;
    notifyListeners();
    try {
      final entrada = await _coordinator.registrarEntrada(
        _tienda,
        producto,
        cantidad,
        costo,
        numeroFactura,
      );
      final nuevoStock = entrada.getItem().getStockActual();
      _aviso = 'Entrada registrada. Nuevo stock: ${mostrarPrecio(nuevoStock)}';
      _cantidad = null;
      _costo = null;
      _costoDifiere = false;
      ++_ultimaVerificacion;
      return true;
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
