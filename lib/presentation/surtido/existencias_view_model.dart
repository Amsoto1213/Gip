import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/consultar_existencias_coordinator.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Qué productos muestra la lista de existencias.
enum FiltroExistencias {
  todos,

  /// Existencia en cero o menos.
  agotados,

  /// Se venden por kilo o por libra.
  porPeso,
}

/// Historial reciente de un producto en el panel desplegado.
@immutable
class HistorialReciente {
  const HistorialReciente._({
    this.cargando = false,
    this.movimientos = const [],
    this.error,
  });

  const HistorialReciente.cargando() : this._(cargando: true);

  const HistorialReciente.listo(List<MovimientoInventario> movimientos)
    : this._(movimientos: movimientos);

  const HistorialReciente.conError(String error) : this._(error: error);

  final bool cargando;

  /// Del más reciente al más antiguo; la vista muestra los primeros
  /// [ExistenciasViewModel.movimientosRecientes].
  final List<MovimientoInventario> movimientos;
  final String? error;
}

/// Estado de la lista de existencias de Surtido (CUS-25). Llama solo a
/// [ConsultarExistenciasCoordinator]. Los periodos son días locales y van de
/// `desde` a `hasta` sin incluir `hasta` (como DI-28).
class ExistenciasViewModel extends ChangeNotifier {
  ExistenciasViewModel(
    this._coordinador,
    this._tienda, {
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  static const mensajeFalla =
      'No se pudieron cargar las existencias. Intente de nuevo';

  static const mensajeFallaHistorial =
      'No se pudo cargar el historial. Intente de nuevo';

  /// El panel desplegado consulta los últimos 30 días, contando hoy (DI-32).
  static const diasRecientes = 30;

  /// Y muestra los 3 más recientes (mockup `mExistencias`).
  static const movimientosRecientes = 3;

  /// Inicio del historial para buscar el último movimiento de un producto
  /// (DI-32): antes de esta fecha no hay datos del GIP.
  static final inicioHistorial = DateTime.utc(2000);

  final ConsultarExistenciasCoordinator _coordinador;
  final Tienda _tienda;
  final DateTime Function() _reloj;

  bool _cargando = false;
  bool _cargado = false;
  String? _error;
  List<ItemInventario> _items = const [];
  FiltroExistencias _filtro = FiltroExistencias.todos;
  String? _abierto;
  HistorialReciente? _historial;

  /// Último movimiento por id de producto; la clave existe desde que se pidió.
  /// Valor nulo: todavía no llega o el producto no tiene movimientos.
  final Map<String, MovimientoInventario?> _ultimos = {};
  final Set<String> _ultimosListos = {};

  /// Cuenta las cargas para descartar las respuestas de una carga vieja.
  int _version = 0;

  bool get cargando => _cargando;

  /// Ya se cargó la lista al menos una vez.
  bool get cargado => _cargado;

  /// Mensaje para el tendero si la lista no se pudo cargar.
  String? get error => _error;

  FiltroExistencias get filtro => _filtro;

  /// Todos los productos de la tienda, ordenados por nombre.
  int get total => _items.length;

  int get agotados => _items.where(estaAgotado).length;

  /// Los productos que deja ver el [filtro], en el orden del coordinador.
  List<ItemInventario> get visibles => switch (_filtro) {
    FiltroExistencias.todos => _items,
    FiltroExistencias.agotados => _items.where(estaAgotado).toList(),
    FiltroExistencias.porPeso => _items.where(_esPorPeso).toList(),
  };

  /// Id del producto con el panel de últimos movimientos abierto, o null.
  String? get abierto => _abierto;

  /// Historial del producto [abierto]; null si no hay ninguno abierto.
  HistorialReciente? get historial => _historial;

  /// Agotado: la existencia es cero o menos.
  static bool estaAgotado(ItemInventario item) =>
      item.getStockActual() <= Decimal.zero;

  static bool _esPorPeso(ItemInventario item) =>
      item.getProducto().getUnidadMedida() != UnidadMedida.unidad;

  /// Hoy a las 00:00, hora local.
  DateTime get _hoy {
    final ahora = _reloj();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  /// Mañana a las 00:00: fin (sin incluir) de los periodos que llegan a hoy.
  DateTime get _manana => DateTime(_hoy.year, _hoy.month, _hoy.day + 1);

  /// Carga (o recarga) la lista: pasos 1 a 8. Si había un panel abierto o
  /// últimos movimientos pedidos, los vuelve a consultar con los datos nuevos.
  Future<void> cargar() async {
    final version = ++_version;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final items = await _coordinador.listarExistencias(_tienda);
      if (version != _version) return;
      _items = items;
      _cargado = true;
    } on ExcepcionNegocio catch (e) {
      if (version != _version) return;
      _error = e.mensaje;
    } catch (_) {
      if (version != _version) return;
      _error = mensajeFalla;
    }
    _cargando = false;
    notifyListeners();
    if (_error != null) return;

    final pedidos = _ultimos.keys.toList();
    _ultimos.clear();
    _ultimosListos.clear();
    for (final item in _items) {
      if (pedidos.contains(item.getProducto().getId())) {
        pedirUltimoMovimiento(item.getProducto());
      }
    }
    final abierto = _items
        .where((i) => i.getProducto().getId() == _abierto)
        .firstOrNull;
    if (abierto == null) {
      _cerrarDetalle();
    } else {
      _cargarHistorial(abierto.getProducto());
    }
  }

  void elegirFiltro(FiltroExistencias filtro) {
    if (filtro == _filtro) return;
    _filtro = filtro;
    notifyListeners();
  }

  /// Ya llegó la respuesta del último movimiento de [producto].
  bool ultimoMovimientoListo(Producto producto) =>
      _ultimosListos.contains(producto.getId());

  /// Último movimiento registrado de [producto], o null si no tiene o si
  /// todavía no llega ([ultimoMovimientoListo]).
  MovimientoInventario? ultimoMovimiento(Producto producto) =>
      _ultimos[producto.getId()];

  /// Consulta el historial completo de [producto] y se queda con el más
  /// reciente (columna "Último movimiento" de la web, DI-32). Lo pide cada
  /// fila al dibujarse; una segunda llamada no vuelve a consultar. Si falla,
  /// la columna queda vacía.
  Future<void> pedirUltimoMovimiento(Producto producto) async {
    final id = producto.getId();
    if (_ultimos.containsKey(id)) return;
    _ultimos[id] = null;
    final version = _version;
    List<MovimientoInventario> movimientos;
    try {
      movimientos = await _coordinador.consultarMovimientos(
        _tienda,
        producto,
        inicioHistorial,
        _manana,
      );
    } catch (_) {
      movimientos = const [];
    }
    if (version != _version || !_ultimos.containsKey(id)) return;
    _ultimos[id] = movimientos.firstOrNull;
    _ultimosListos.add(id);
    notifyListeners();
  }

  /// Abre el panel de últimos movimientos de [producto] (opt Historial, pasos
  /// 9 a 18, con los últimos [diasRecientes] días) o lo cierra si ya estaba
  /// abierto. Solo hay un panel abierto a la vez.
  Future<void> alternarDetalle(Producto producto) async {
    if (_abierto == producto.getId()) {
      _cerrarDetalle();
      return;
    }
    await _cargarHistorial(producto);
  }

  void _cerrarDetalle() {
    _abierto = null;
    _historial = null;
    notifyListeners();
  }

  Future<void> _cargarHistorial(Producto producto) async {
    final id = producto.getId();
    _abierto = id;
    _historial = const HistorialReciente.cargando();
    notifyListeners();
    final hoy = _hoy;
    HistorialReciente historial;
    try {
      historial = HistorialReciente.listo(
        await _coordinador.consultarMovimientos(
          _tienda,
          producto,
          DateTime(hoy.year, hoy.month, hoy.day - (diasRecientes - 1)),
          _manana,
        ),
      );
    } on ExcepcionNegocio catch (e) {
      historial = HistorialReciente.conError(e.mensaje);
    } catch (_) {
      historial = const HistorialReciente.conError(mensajeFallaHistorial);
    }
    if (_abierto != id) return;
    _historial = historial;
    notifyListeners();
  }
}
