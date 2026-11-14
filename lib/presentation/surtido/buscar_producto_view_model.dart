import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/buscar_producto_coordinator.dart';

/// En qué punto está la búsqueda.
enum EstadoBusqueda { inicial, buscando, conResultados, sinCoincidencias }

/// Estado de la pantalla Buscar producto (CUS-06, búsqueda por nombre). Llama
/// solo a [BuscarProductoCoordinator].
///
/// Busca en cada cambio del texto (filtro en tiempo real). Si una consulta
/// vieja termina después de una más nueva, su resultado se descarta.
class BuscarProductoViewModel extends ChangeNotifier {
  BuscarProductoViewModel(this._coordinator, this._tienda);

  /// Mensaje del diagrama cuando no hay coincidencias.
  static const mensajeSinCoincidencias =
      'No se encontró el producto. ¿Desea crearlo?';

  final BuscarProductoCoordinator _coordinator;
  final Tienda _tienda;

  String _texto = '';
  List<Producto> _productos = const [];
  EstadoBusqueda _estado = EstadoBusqueda.inicial;
  String? _error;
  int _ultimaConsulta = 0;
  bool _cerrado = false;

  String get texto => _texto;
  List<Producto> get productos => _productos;
  EstadoBusqueda get estado => _estado;

  /// Mensaje de error para el tendero, o null.
  String? get error => _error;

  /// Busca [texto] en el catálogo de la tienda. Con el texto vacío no busca y
  /// vuelve al estado inicial.
  Future<void> buscar(String texto) async {
    _texto = texto;
    _error = null;
    final consulta = ++_ultimaConsulta;
    if (texto.trim().isEmpty) {
      _productos = const [];
      _estado = EstadoBusqueda.inicial;
      notifyListeners();
      return;
    }

    _estado = EstadoBusqueda.buscando;
    notifyListeners();
    try {
      final productos = await _coordinator.buscarPorNombre(_tienda, texto);
      if (_cerrado || consulta != _ultimaConsulta) return;
      _productos = productos;
      _estado = productos.isEmpty
          ? EstadoBusqueda.sinCoincidencias
          : EstadoBusqueda.conResultados;
    } catch (_) {
      if (_cerrado || consulta != _ultimaConsulta) return;
      _productos = const [];
      _estado = EstadoBusqueda.inicial;
      _error = 'No se pudo buscar el producto. Inténtalo de nuevo';
    }
    notifyListeners();
  }

  /// Repite la búsqueda actual; se usa al volver de crear o editar un
  /// producto.
  Future<void> repetirBusqueda() => buscar(_texto);

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
