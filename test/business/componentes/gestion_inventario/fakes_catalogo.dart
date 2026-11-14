import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_inventario_repositorio.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_producto_repositorio.dart';
import 'package:gip/business/interfaces/i_unidad_trabajo.dart';

/// Repositorio falso con copia de seguridad para simular el rollback.
abstract class Restaurable {
  void tomarCopia();
  void restaurar();
}

/// Ejecuta la acción; si falla, restaura los repositorios (todo o nada).
/// Cuenta las transacciones y avisa si hay una abierta.
class UnidadTrabajoFalsa implements IUnidadTrabajo {
  UnidadTrabajoFalsa(this._repositorios);

  final List<Restaurable> _repositorios;
  int transacciones = 0;
  bool abierta = false;

  @override
  Future<void> ejecutar(Future<void> Function() accion) async {
    if (abierta) return accion();
    transacciones++;
    abierta = true;
    for (final r in _repositorios) {
      r.tomarCopia();
    }
    try {
      await accion();
    } catch (_) {
      for (final r in _repositorios) {
        r.restaurar();
      }
      rethrow;
    } finally {
      abierta = false;
    }
  }
}

class ProductoRepositorioFalso implements IProductoRepositorio, Restaurable {
  /// Por tienda: id de producto → producto.
  final Map<String, Map<String, Producto>> datos = {};
  Map<String, Map<String, Producto>> _copia = {};

  /// Para cada guardar: si había una transacción abierta.
  final List<bool> guardadosEnTransaccion = [];
  UnidadTrabajoFalsa? unidad;

  Map<String, Producto> _de(Tienda t) => datos.putIfAbsent(t.getId(), () => {});

  @override
  void tomarCopia() =>
      _copia = {for (final e in datos.entries) e.key: Map.of(e.value)};

  @override
  void restaurar() => datos
    ..clear()
    ..addAll(_copia);

  @override
  Future<Producto?> buscarPorCodigo(Tienda tienda, String codigo) async =>
      _de(tienda).values.where((p) => p.getCodigo() == codigo).firstOrNull;

  @override
  Future<Producto?> buscarPorId(Tienda tienda, String id) async =>
      _de(tienda)[id];

  @override
  Future<void> guardar(Tienda tienda, Producto producto) async {
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    _de(tienda)[producto.getId()] = producto;
  }

  @override
  Future<List<Producto>> listar(Tienda tienda) async =>
      _de(tienda).values.toList()
        ..sort((a, b) => a.getNombre().compareTo(b.getNombre()));

  /// Textos con que se llamó a buscarPorNombre.
  final List<String> textosBuscados = [];

  /// Coincidencia parcial sin mayúsculas (las tildes las prueba el
  /// repositorio drift).
  @override
  Future<List<Producto>> buscarPorNombre(Tienda tienda, String texto) async {
    textosBuscados.add(texto);
    final buscado = texto.toLowerCase();
    return (await listar(tienda))
        .where((p) => p.getNombre().toLowerCase().contains(buscado))
        .toList();
  }

  @override
  Future<Producto?> buscarPorCodigoProducto(Tienda tienda, String valor) =>
      throw UnimplementedError();

  @override
  Future<List<CodigoProducto>> listarCodigosRepetidos(Tienda tienda) =>
      throw UnimplementedError();
}

class InventarioRepositorioFalso
    implements IInventarioRepositorio, Restaurable {
  final Map<String, Map<String, ItemInventario>> datos = {};
  Map<String, Map<String, ItemInventario>> _copia = {};

  final List<bool> guardadosEnTransaccion = [];
  UnidadTrabajoFalsa? unidad;

  /// Si es verdadero, guardarItem falla (para probar el rollback).
  bool fallar = false;

  Map<String, ItemInventario> _de(Tienda t) =>
      datos.putIfAbsent(t.getId(), () => {});

  @override
  void tomarCopia() =>
      _copia = {for (final e in datos.entries) e.key: Map.of(e.value)};

  @override
  void restaurar() => datos
    ..clear()
    ..addAll(_copia);

  /// Guarda y devuelve copias, como una base de datos: cambiar el stock de un
  /// ítem leído no cambia lo guardado hasta que se llama a guardarItem.
  static ItemInventario _copiar(ItemInventario i) =>
      ItemInventario(i.getId(), i.getProducto(), i.getStockActual());

  @override
  Future<ItemInventario?> buscarItem(Tienda tienda, Producto producto) async {
    final item = _de(tienda).values
        .where((i) => i.getProducto().getId() == producto.getId())
        .firstOrNull;
    return item == null ? null : _copiar(item);
  }

  @override
  Future<void> guardarItem(Tienda tienda, ItemInventario item) async {
    if (fallar) throw StateError('falla del disco');
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    _de(tienda)[item.getId()] = _copiar(item);
  }

  @override
  Future<List<ItemInventario>> listarItems(Tienda tienda) async =>
      _de(tienda).values.map(_copiar).toList();
}
