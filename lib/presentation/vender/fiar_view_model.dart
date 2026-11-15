import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/workflow/pagos/registrar_fiado_coordinator.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Lo que Cobrar le pasa a Fiar: el total de la venta, lo que ya cubren el
/// efectivo y Nequi, con qué ([detallePagado]: "efectivo", "Nequi"…) y lo que
/// falta, que es el monto que se sugiere fiar.
typedef DatosFiar = ({
  Decimal total,
  Decimal yaPago,
  String detallePagado,
  Decimal falta,
});

/// Estado de la pantalla Fiar (CUS-07, mockups `mFiar` y `wFiar`). Llama solo
/// a [RegistrarFiadoCoordinator]: busca al cliente, registra uno nuevo y
/// prepara el fiado, que queda en memoria y vuelve a Cobrar; se guarda al
/// confirmar la venta (DA-57).
class FiarViewModel extends ChangeNotifier {
  FiarViewModel(this._coordinator, this._tienda, this.datos)
    : montoInicial = datos.falta > Decimal.zero
          ? mostrarPrecio(datos.falta)
          : '',
      _monto = datos.falta > Decimal.zero ? datos.falta : null;

  /// Mensajes de la pantalla que no están en el diagrama (DI-26).
  static const mensajeErrorBuscar =
      'No se pudieron buscar los clientes. Intente de nuevo';
  static const mensajeErrorRegistrar =
      'No se pudo registrar el cliente. Intente de nuevo';

  final RegistrarFiadoCoordinator _coordinator;
  final Tienda _tienda;
  final DatosFiar datos;

  /// Texto con que empieza el campo del monto: lo que falta por cubrir.
  final String montoInicial;

  List<Cliente> _clientes = const [];
  Cliente? _cliente;
  bool _buscando = false;
  String _busqueda = '';
  int _consulta = 0;
  String? _errorBusqueda;
  bool _creandoCliente = false;
  bool _registrando = false;
  String? _errorNombre;
  Decimal? _monto;
  String? _errorMonto;

  /// Clientes encontrados; el elegido va siempre, aunque la búsqueda cambie.
  List<Cliente> get clientes {
    final elegido = _cliente;
    if (elegido == null || _clientes.any((c) => c.getId() == elegido.getId())) {
      return _clientes;
    }
    return [elegido, ..._clientes];
  }

  Cliente? get cliente => _cliente;
  bool get buscando => _buscando;

  /// Verdadero si se buscó algo y no salió ningún cliente.
  bool get sinResultados =>
      _busqueda.trim().isNotEmpty && !_buscando && _clientes.isEmpty;

  String? get errorBusqueda => _errorBusqueda;
  bool get creandoCliente => _creandoCliente;
  bool get registrando => _registrando;

  /// "El nombre del cliente es obligatorio", o null.
  String? get errorNombre => _errorNombre;

  /// "El monto del fiado debe ser mayor que cero", o null.
  String? get errorMonto => _errorMonto;

  /// Lo que el cliente quedará debiendo con este fiado, o null si aún no hay
  /// cliente o monto.
  Decimal? get deudaTotal {
    final cliente = _cliente;
    final monto = _monto;
    if (cliente == null || monto == null || monto <= Decimal.zero) return null;
    return cliente.calcularSaldoPendiente() + monto;
  }

  bool get puedeAgregar => _cliente != null && !_registrando;

  /// Busca por nombre sin tildes ni mayúsculas (RD-08). Sin texto no muestra
  /// ninguno. Si llega una respuesta vieja, la descarta.
  Future<void> buscar(String texto) async {
    _busqueda = texto;
    _errorBusqueda = null;
    final consulta = ++_consulta;
    if (texto.trim().isEmpty) {
      _clientes = const [];
      _buscando = false;
      notifyListeners();
      return;
    }
    _buscando = true;
    notifyListeners();
    try {
      final encontrados = await _coordinator.buscarClientes(_tienda, texto);
      if (consulta != _consulta) return;
      _clientes = encontrados;
    } catch (_) {
      if (consulta != _consulta) return;
      _clientes = const [];
      _errorBusqueda = mensajeErrorBuscar;
    }
    _buscando = false;
    notifyListeners();
  }

  void elegir(Cliente cliente) {
    _cliente = cliente;
    _creandoCliente = false;
    _errorNombre = null;
    notifyListeners();
  }

  /// "+ Cliente nuevo (nombre y teléfono)" y su "Cancelar".
  void mostrarClienteNuevo(bool mostrar) {
    _creandoCliente = mostrar;
    _errorNombre = null;
    notifyListeners();
  }

  /// Registra el cliente nuevo y lo deja elegido (extensión de CUS-07). Se
  /// guarda de una vez, aunque luego no se confirme la venta (DI-26).
  /// Devuelve verdadero si quedó registrado.
  Future<bool> registrarCliente(String nombre, String telefono) async {
    if (_registrando) return false;
    _registrando = true;
    _errorNombre = null;
    notifyListeners();
    try {
      final nuevo = await _coordinator.registrarCliente(
        _tienda,
        nombre,
        telefono,
      );
      _cliente = nuevo;
      _creandoCliente = false;
      return true;
    } on ExcepcionNegocio catch (e) {
      _errorNombre = e.mensaje;
      return false;
    } catch (_) {
      _errorNombre = mensajeErrorRegistrar;
      return false;
    } finally {
      _registrando = false;
      notifyListeners();
    }
  }

  /// Monto como lo escribe el tendero ("8.400").
  void cambiarMonto(String texto) {
    _monto = leerPesos(texto);
    _errorMonto = null;
    notifyListeners();
  }

  /// prepararFiado: devuelve el [Fiado] en memoria para agregarlo a las
  /// formas de pago, o null si el monto no es válido (pasos 11 a 19). Un
  /// monto vacío o que no es número cuenta como cero.
  Fiado? agregar() {
    final cliente = _cliente;
    if (cliente == null) return null;
    try {
      return _coordinator.prepararFiado(cliente, _monto ?? Decimal.zero);
    } on ExcepcionNegocio catch (e) {
      _errorMonto = e.mensaje;
      notifyListeners();
      return null;
    }
  }
}
