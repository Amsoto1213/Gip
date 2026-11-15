import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_conteo_coordinator.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/surtido/perdida_view_model.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';
import 'package:gip/transversal/texto/normalizar_texto.dart';

/// Qué filas muestra la lista del conteo.
enum FiltroConteo { todos, contados, sinContar, conDiferencia }

/// Un producto de la lista del conteo con lo que el tendero lleva escrito.
@immutable
class FilaConteo {
  const FilaConteo({
    required this.item,
    this.texto = '',
    this.contada,
    this.diferencia,
    this.revisar = false,
    this.error,
  });

  /// Ítem con su producto y el stock según el sistema.
  final ItemInventario item;

  /// Cantidad como la escribió el tendero.
  final String texto;

  /// Cantidad contada, o null si no ha escrito un número válido.
  final Decimal? contada;

  /// contada − stock, la que devuelve el coordinador; null mientras no se
  /// conoce.
  final Decimal? diferencia;

  /// |diferencia| supera el umbral: "Revise el conteo antes de confirmar".
  final bool revisar;

  /// Mensaje para el tendero en esta fila, o null.
  final String? error;

  Producto get producto => item.getProducto();

  bool get contado => contada != null;

  /// Kilos y libras admiten decimales; la unidad, no (IE-01 b).
  bool get admiteDecimales => producto.getUnidadMedida() != UnidadMedida.unidad;

  FilaConteo _con({
    ItemInventario? item,
    String? texto,
    Decimal? contada,
    Decimal? diferencia,
    bool revisar = false,
    String? error,
  }) => FilaConteo(
    item: item ?? this.item,
    texto: texto ?? this.texto,
    contada: contada,
    diferencia: diferencia,
    revisar: revisar,
    error: error,
  );
}

/// Estado de la pantalla Conteo físico (CUS-04). Llama solo a
/// [RegistrarConteoCoordinator].
///
/// Carga los productos con `listarExistencias`. Al escribir una cantidad pide
/// la diferencia (`calcularDiferencia`) y si requiere revisión
/// (`requiereRevision`); el aviso no bloquea. Confirmar llama a
/// `confirmarAjuste` por cada producto contado, uno tras otro como el loop del
/// diagrama: cada uno es su propia transacción (DI-24).
class ConteoViewModel extends ChangeNotifier {
  ConteoViewModel(this._coordinator, this._tienda);

  /// Mensajes del diagrama (pasos 24 y 39).
  static const mensajeRevisar =
      'La diferencia supera el umbral. Revise el conteo antes de confirmar';
  static const mensajeErrorGuardar =
      'No se pudo registrar el ajuste. Intente de nuevo';
  static const mensajeErrorCargar =
      'No se pudieron cargar los productos. Intente de nuevo';
  static const mensajeSoloEnteros = PerdidaViewModel.mensajeSoloEnteros;

  final RegistrarConteoCoordinator _coordinator;
  final Tienda _tienda;

  List<FilaConteo> _filas = const [];
  String _busqueda = '';
  FiltroConteo _filtro = FiltroConteo.todos;
  bool _cargando = false;
  bool _registrando = false;
  String? _error;
  String? _aviso;
  final Map<String, int> _ultimaConsulta = {};
  Set<String> _visibles = const {};
  bool _cerrado = false;

  bool get cargando => _cargando;

  bool get registrando => _registrando;

  /// Error general de la pantalla (cargar o guardar), o null.
  String? get error => _error;

  /// "Ajuste registrado. Nuevo stock: N" o "Ajuste registrado en N
  /// productos", o null.
  String? get aviso => _aviso;

  String get busqueda => _busqueda;

  FiltroConteo get filtro => _filtro;

  /// Todos los productos de la tienda, en el orden del repositorio (nombre).
  List<FilaConteo> get todas => List.unmodifiable(_filas);

  /// Filas que pasan el filtro por nombre (normalizado como en CUS-06) y el
  /// filtro elegido. Cuáles pasan se decide al buscar, al elegir el filtro, al
  /// cargar y al confirmar, no al escribir una cantidad: así la fila en la que
  /// el tendero escribe no se va de la lista (con "Sin contar", por ejemplo).
  List<FilaConteo> get filas =>
      _filas.where((f) => _visibles.contains(f.producto.getId())).toList();

  void _fijarVisibles() => _visibles = {
    for (final f in _filas)
      if (_pasaFiltro(f)) f.producto.getId(),
  };

  bool _pasaFiltro(FilaConteo f) {
    final buscado = normalizarTexto(_busqueda);
    if (buscado.isNotEmpty &&
        !normalizarTexto(f.producto.getNombre()).contains(buscado)) {
      return false;
    }
    return switch (_filtro) {
      FiltroConteo.todos => true,
      FiltroConteo.contados => f.contado,
      FiltroConteo.sinContar => !f.contado,
      FiltroConteo.conDiferencia => _conDiferencia(f),
    };
  }

  int get total => _filas.length;

  int get contados => _filas.where((f) => f.contado).length;

  int get sinContar => total - contados;

  int get conDiferencia => _filas.where(_conDiferencia).length;

  /// Productos cuya diferencia supera el umbral.
  int get porRevisar => _filas.where((f) => f.revisar).length;

  /// Hay algo contado, nada escrito que no sea un número válido y no se está
  /// guardando.
  bool get puedeConfirmar =>
      contados > 0 &&
      !_registrando &&
      !_filas.any((f) => f.texto.trim().isNotEmpty && !f.contado);

  static bool _conDiferencia(FilaConteo f) =>
      f.diferencia != null && f.diferencia != Decimal.zero;

  /// listarExistencias del coordinador (pasos 2 a 8).
  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final items = await _coordinator.listarExistencias(_tienda);
      if (_cerrado) return;
      _filas = [for (final item in items) FilaConteo(item: item)];
      _fijarVisibles();
    } on ExcepcionNegocio catch (e) {
      if (_cerrado) return;
      _error = e.mensaje;
    } catch (_) {
      if (_cerrado) return;
      _error = mensajeErrorCargar;
    } finally {
      _cargando = false;
      if (!_cerrado) notifyListeners();
    }
  }

  void buscar(String texto) {
    _busqueda = texto;
    _fijarVisibles();
    notifyListeners();
  }

  void elegirFiltro(FiltroConteo filtro) {
    _filtro = filtro;
    _fijarVisibles();
    notifyListeners();
  }

  /// Cantidad contada de [producto] como la escribe el tendero (paso 9);
  /// acepta coma o punto decimal en kilos y libras. Pide la diferencia y si
  /// requiere revisión (pasos 10 a 22).
  Future<void> cambiarCantidad(Producto producto, String texto) async {
    final i = _indice(producto);
    if (i < 0) return;
    final fila = _filas[i];
    final valor = PerdidaViewModel.leerCantidad(texto);
    final fraccionEnUnidades =
        valor != null && !fila.admiteDecimales && !valor.isInteger;
    final contada = fraccionEnUnidades ? null : valor;
    _aviso = null;
    _reemplazar(
      i,
      fila._con(
        texto: texto,
        contada: contada,
        error: fraccionEnUnidades ? mensajeSoloEnteros : null,
      ),
    );
    notifyListeners();
    if (contada == null) {
      _ultimaConsulta[producto.getId()] =
          (_ultimaConsulta[producto.getId()] ?? 0) + 1;
      return;
    }
    await _consultarDiferencia(producto, contada);
  }

  /// "Volver a contar": borra la cantidad de [producto] para escribirla de
  /// nuevo.
  void volverAContar(Producto producto) => cambiarCantidad(producto, '');

  /// confirmarAjuste por cada producto contado (pasos 25 a 39). Los que se
  /// guardan quedan con su nuevo stock y sin cantidad; los que fallan siguen
  /// en la lista con su mensaje. Un error que no es de negocio detiene el
  /// recorrido: lo ya guardado queda guardado.
  Future<void> confirmar() async {
    if (!puedeConfirmar) return;
    _registrando = true;
    _error = null;
    _aviso = null;
    notifyListeners();
    final registrados = <ItemInventario>[];
    try {
      for (final fila in _filas.where((f) => f.contado).toList()) {
        final producto = fila.producto;
        try {
          final ajuste = await _coordinator.confirmarAjuste(
            _tienda,
            producto,
            fila.contada!,
          );
          if (_cerrado) return;
          registrados.add(ajuste.getItem());
          final i = _indice(producto);
          _ultimaConsulta[producto.getId()] =
              (_ultimaConsulta[producto.getId()] ?? 0) + 1;
          _reemplazar(i, FilaConteo(item: ajuste.getItem()));
        } on ExcepcionNegocio catch (e) {
          if (_cerrado) return;
          final i = _indice(producto);
          _reemplazar(
            i,
            _filas[i]._con(
              contada: _filas[i].contada,
              diferencia: _filas[i].diferencia,
              revisar: _filas[i].revisar,
              error: e.mensaje,
            ),
          );
        }
      }
    } catch (_) {
      if (_cerrado) return;
      _error = mensajeErrorGuardar;
    } finally {
      _registrando = false;
      _fijarVisibles();
      if (!_cerrado) {
        if (registrados.length == 1) {
          _aviso =
              'Ajuste registrado. Nuevo stock: '
              '${mostrarPrecio(registrados.single.getStockActual())}';
        } else if (registrados.length > 1) {
          _aviso = 'Ajuste registrado en ${registrados.length} productos';
        }
        notifyListeners();
      }
    }
  }

  /// calcularDiferencia y requiereRevision del coordinador; descarta la
  /// respuesta de una consulta vieja del mismo producto.
  Future<void> _consultarDiferencia(Producto producto, Decimal contada) async {
    final id = producto.getId();
    final consulta = (_ultimaConsulta[id] ?? 0) + 1;
    _ultimaConsulta[id] = consulta;
    String? error;
    Decimal? diferencia;
    var revisar = false;
    try {
      diferencia = await _coordinator.calcularDiferencia(
        _tienda,
        producto,
        contada,
      );
      revisar = _coordinator.requiereRevision(diferencia);
    } on ExcepcionNegocio catch (e) {
      error = e.mensaje;
    } catch (_) {
      // La diferencia es informativa: si no se puede leer, no se muestra.
    }
    if (_cerrado || _ultimaConsulta[id] != consulta) return;
    final i = _indice(producto);
    if (i < 0) return;
    _reemplazar(
      i,
      _filas[i]._con(
        contada: _filas[i].contada,
        diferencia: diferencia,
        revisar: revisar,
        error: error,
      ),
    );
    notifyListeners();
  }

  int _indice(Producto producto) =>
      _filas.indexWhere((f) => f.producto.getId() == producto.getId());

  void _reemplazar(int i, FilaConteo fila) => _filas = [..._filas]..[i] = fila;

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
