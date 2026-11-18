import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/buscar_producto_coordinator.dart';

/// En qué punto está la búsqueda.
enum EstadoBusqueda { inicial, buscando, conResultados, sinCoincidencias }

/// Estado de la pantalla Buscar producto: búsqueda por nombre (CUS-06) y por
/// lectura del lector 2D o la cámara (CUS-17). Llama solo a
/// [BuscarProductoCoordinator].
///
/// Busca por nombre en cada cambio del texto (filtro en tiempo real). Si una
/// consulta vieja termina después de una más nueva, su resultado se descarta.
class BuscarProductoViewModel extends ChangeNotifier {
  BuscarProductoViewModel(this._coordinator, this._tienda);

  /// Mensaje del diagrama cuando no hay coincidencias (CUS-06 y, para un
  /// código que no está registrado, CUS-17 → CUS-18).
  static const mensajeSinCoincidencias =
      'No se encontró el producto. ¿Desea crearlo?';

  /// Lectura fallida con la cámara (CUS-17, paso 6; el texto no está en el
  /// diagrama, DI-34). Se sigue con la búsqueda por nombre.
  static const mensajeCamaraNoDisponible =
      'No se pudo usar la cámara. Busque el producto por nombre';

  final BuscarProductoCoordinator _coordinator;
  final Tienda _tienda;

  String _texto = '';
  List<Producto> _productos = const [];
  EstadoBusqueda _estado = EstadoBusqueda.inicial;
  String? _error;
  String? _avisoLectura;
  String? _codigoNoRegistrado;
  bool _porLectura = false;
  int _ultimaConsulta = 0;
  bool _cerrado = false;

  String get texto => _texto;
  List<Producto> get productos => _productos;
  EstadoBusqueda get estado => _estado;

  /// Mensaje de error para el tendero, o null.
  String? get error => _error;

  /// Aviso de una lectura fallida (cámara), o null.
  String? get avisoLectura => _avisoLectura;

  /// Código leído que ningún producto tiene. Si no es null, "Crear producto"
  /// lo lleva para asociarlo al producto nuevo (CUS-18).
  String? get codigoNoRegistrado => _codigoNoRegistrado;

  /// Busca [texto] en el catálogo de la tienda. Con el texto vacío no busca y
  /// vuelve al estado inicial.
  Future<void> buscar(String texto) async {
    _texto = texto;
    _error = null;
    _avisoLectura = null;
    _codigoNoRegistrado = null;
    _porLectura = false;
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

  /// Repite la búsqueda actual (por nombre o por lectura de la cámara); se
  /// usa al volver de crear o editar un producto.
  Future<void> repetirBusqueda() async {
    if (_porLectura) {
      await buscarPorLectura(_texto, desdeCamara: true);
    } else {
      await buscar(_texto);
    }
  }

  /// Busca el producto que tiene el código [lectura] (CUS-17). Devuelve el
  /// producto para que la pantalla siga el flujo que abrió la búsqueda, o
  /// null.
  ///
  /// Si no lo encuentra y la búsqueda por nombre tampoco tiene resultados,
  /// queda [codigoNoRegistrado] y se ofrece crearlo. Si hay resultados por
  /// nombre (se escribió un nombre y se oprimió Enter), se dejan como están.
  /// Con [desdeCamara] la lectura reemplaza el texto y los resultados. El
  /// producto encontrado queda como único resultado si viene de la cámara o
  /// si no hay resultados por nombre.
  Future<Producto?> buscarPorLectura(
    String lectura, {
    bool desdeCamara = false,
  }) async {
    final codigo = lectura.trim();
    if (codigo.isEmpty) return null;
    _error = null;
    _avisoLectura = null;
    _codigoNoRegistrado = null;
    if (desdeCamara) {
      _texto = codigo;
      _porLectura = true;
      _productos = const [];
      _estado = EstadoBusqueda.buscando;
      ++_ultimaConsulta;
      notifyListeners();
    }
    final consulta = _ultimaConsulta;
    try {
      final producto = await _coordinator.buscarPorLectura(_tienda, codigo);
      if (_cerrado) return null;
      if (producto != null) {
        // Sin resultados por nombre (un código no coincide con nombres), el
        // producto leído queda como resultado y al volver se repite la
        // lectura. Se descarta la búsqueda por nombre que siga en curso.
        if (consulta == _ultimaConsulta &&
            (desdeCamara || _productos.isEmpty)) {
          ++_ultimaConsulta;
          _porLectura = true;
          _productos = [producto];
          _estado = EstadoBusqueda.conResultados;
          notifyListeners();
        }
        return producto;
      }
      // El tendero siguió escribiendo: manda lo nuevo.
      if (consulta != _ultimaConsulta) return null;
      if (_productos.isEmpty) {
        _codigoNoRegistrado = codigo;
        _estado = EstadoBusqueda.sinCoincidencias;
      }
    } catch (_) {
      if (_cerrado) return null;
      _error = 'No se pudo buscar el producto. Inténtalo de nuevo';
      if (desdeCamara) _estado = EstadoBusqueda.inicial;
    }
    notifyListeners();
    return null;
  }

  /// La cámara no se pudo usar (CUS-17, alt "Lectura fallida"): se muestra
  /// el aviso y se sigue con la búsqueda por nombre.
  void lecturaFallida() {
    _avisoLectura = mensajeCamaraNoDisponible;
    notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
