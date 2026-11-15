import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/workflow/pagos/consultar_cliente_coordinator.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Filtros de la lista de clientes (mockups `mClientes` y `wClientes`). El
/// filtro "+30 días" llega con CUS-19 completo (DI-27).
enum FiltroClientes { deben, todos }

/// Estado de la sección Fiados (CUS-19 mínimo, mockups `mClientes`, `Cliente`
/// y `wClientes`). Llama solo a [ConsultarClienteCoordinator]: busca a los
/// clientes con sus fiados y abonos y calcula lo que deben. El cliente
/// elegido y la lista se vuelven a leer de la base con [recargar], por
/// ejemplo después de un abono (DI-27).
class FiadosViewModel extends ChangeNotifier {
  FiadosViewModel(this._coordinator, this._tienda);

  /// Mensajes de la pantalla que no están en el diagrama (DI-27).
  static const mensajeErrorCargar =
      'No se pudieron cargar los clientes. Intente de nuevo';

  /// Mensaje de CUS-21 al terminar (paso 14).
  static const mensajeClienteEliminado = 'Datos del cliente eliminados';

  /// Error de CUS-21 que no es de negocio (la base falló); no está en el
  /// diagrama (DI-31).
  static const mensajeErrorEliminar =
      'No se pudieron eliminar los datos del cliente. Intente de nuevo';

  final ConsultarClienteCoordinator _coordinator;
  final Tienda _tienda;

  List<Cliente> _clientes = const [];
  String _busqueda = '';
  FiltroClientes _filtro = FiltroClientes.deben;
  Cliente? _elegido;
  bool _cargando = false;
  bool _cargaInicial = true;
  String? _error;
  String? _aviso;
  int _consulta = 0;
  int _generacion = 0;
  Decimal _deudaTotal = Decimal.zero;
  int _deudores = 0;

  /// Clientes de la búsqueda, ya con el filtro aplicado.
  List<Cliente> get clientes => switch (_filtro) {
    FiltroClientes.deben =>
      _clientes.where((c) => _saldo(c) > Decimal.zero).toList(),
    FiltroClientes.todos => _clientes,
  };

  FiltroClientes get filtro => _filtro;
  String get busqueda => _busqueda;
  Cliente? get elegido => _elegido;
  bool get cargando => _cargando;

  /// Verdadero hasta que termina la primera lectura.
  bool get cargaInicial => _cargaInicial;

  /// "No se pudieron cargar los clientes. Intente de nuevo", o null.
  String? get error => _error;

  /// Error de un abono que no se guardó, para mostrarlo en el cliente.
  String? get aviso => _aviso;

  /// Cambia cada vez que se vuelve a leer el cliente de la base; el panel de
  /// abono lo usa para empezar de nuevo con los fiados recién leídos.
  int get generacion => _generacion;

  /// Lo que deben todos los clientes de la tienda.
  Decimal get deudaTotal => _deudaTotal;

  /// Cuántos clientes deben algo.
  int get deudores => _deudores;

  /// Verdadero si se buscó algo y no salió ningún cliente.
  bool get sinResultados =>
      !_cargando &&
      _error == null &&
      _busqueda.trim().isNotEmpty &&
      _clientes.isEmpty;

  /// Saldo de un cliente: lo calcula el coordinador (CUS-19, paso 11).
  Decimal saldoDe(Cliente cliente) => _saldo(cliente);

  Decimal _saldo(Cliente cliente) => _coordinator.consultarSaldoTotal(cliente);

  /// Lee los clientes de la tienda (búsqueda vacía) o los que coinciden con
  /// el texto, sin mayúsculas ni tildes (RD-08). Si llega una respuesta
  /// vieja, la descarta.
  Future<void> cargar([String? texto]) async {
    if (texto != null) _busqueda = texto;
    final consulta = ++_consulta;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final encontrados = await _coordinator.buscarClientes(
        _tienda,
        _busqueda.trim(),
      );
      if (consulta != _consulta) return;
      _clientes = encontrados;
      if (_busqueda.trim().isEmpty) _calcularResumen(encontrados);
    } catch (_) {
      if (consulta != _consulta) return;
      _clientes = const [];
      _error = mensajeErrorCargar;
    }
    _cargando = false;
    _cargaInicial = false;
    notifyListeners();
  }

  void _calcularResumen(List<Cliente> todos) {
    var total = Decimal.zero;
    var deudores = 0;
    for (final c in todos) {
      final saldo = _saldo(c);
      if (saldo > Decimal.zero) {
        total += saldo;
        deudores++;
      }
    }
    _deudaTotal = total;
    _deudores = deudores;
  }

  Future<void> buscar(String texto) => cargar(texto);

  void filtrar(FiltroClientes filtro) {
    _filtro = filtro;
    notifyListeners();
  }

  /// Elige al cliente para ver su saldo y sus fiados. Quita el aviso de un
  /// abono anterior.
  void elegir(Cliente? cliente) {
    _elegido = cliente;
    _aviso = null;
    notifyListeners();
  }

  /// Muestra el error de un abono que no se guardó.
  void avisar(String mensaje) {
    _aviso = mensaje;
    notifyListeners();
  }

  /// CUS-21 (pasos 4 a 13): elimina los datos del cliente. La pantalla ya
  /// pidió la confirmación (RNF-26). Si tiene fiados pendientes deja el
  /// mensaje del caso de uso en [aviso]. Si sale bien, ya no hay cliente
  /// elegido y la lista se lee de nuevo. Termina con verdadero si se
  /// eliminó.
  Future<bool> eliminarCliente(Cliente cliente) async {
    try {
      await _coordinator.eliminarCliente(_tienda, cliente);
    } on ExcepcionNegocio catch (e) {
      avisar(e.mensaje);
      return false;
    } catch (_) {
      avisar(mensajeErrorEliminar);
      return false;
    }
    _elegido = null;
    _aviso = null;
    await recargar();
    return true;
  }

  /// Vuelve a leer la lista y el cliente elegido de la base. Tras un abono
  /// que falló, el [Fiado] en memoria quedó con el saldo ya rebajado aunque la
  /// base se deshizo: esta lectura lo corrige (DI-27).
  Future<void> recargar() async {
    final idElegido = _elegido?.getId();
    final texto = _busqueda;
    final consulta = ++_consulta;
    try {
      final todos = await _coordinator.buscarClientes(_tienda, '');
      final encontrados = texto.trim().isEmpty
          ? todos
          : await _coordinator.buscarClientes(_tienda, texto.trim());
      if (consulta != _consulta) return;
      _clientes = encontrados;
      _calcularResumen(todos);
      _error = null;
      if (idElegido != null) {
        _elegido = todos.where((c) => c.getId() == idElegido).firstOrNull;
      }
    } catch (_) {
      if (consulta != _consulta) return;
      _error = mensajeErrorCargar;
    }
    _cargando = false;
    _cargaInicial = false;
    _generacion++;
    notifyListeners();
  }
}
