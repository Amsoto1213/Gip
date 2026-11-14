import 'package:drift/drift.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_producto_repositorio.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/data/helpers/normalizar_texto.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/mapeo_producto.dart';

/// [IProductoRepositorio] sobre la base local (drift). Toda consulta filtra por
/// `tienda_id`.
///
/// Los códigos de barras o QR todavía no se guardan: la tabla
/// `codigos_producto` llega con "Asociar código" (CUS-17). Mientras tanto los
/// productos se leen sin códigos.
class ProductoRepositorioDrift implements IProductoRepositorio {
  ProductoRepositorioDrift(this._base);

  final BaseLocalDrift _base;

  static const _tabla = 'productos';

  SimpleSelectStatement<$ProductosTable, FilaProducto> _deTienda(
    Tienda tienda,
  ) =>
      _base.select(_base.productos)
        ..where((p) => p.tiendaId.equals(tienda.getId()));

  @override
  Future<List<Producto>> buscarPorNombre(Tienda tienda, String texto) async {
    final patron = '%${_escaparLike(normalizarTexto(texto))}%';
    final filas =
        await (_deTienda(tienda)
              ..where((p) => p.nombreNormalizado.like(patron, escapeChar: r'\'))
              ..orderBy([(p) => OrderingTerm.asc(p.nombreNormalizado)]))
            .get();
    return filas.map(MapeoProducto.aEntidad).toList();
  }

  @override
  Future<Producto?> buscarPorCodigo(Tienda tienda, String codigo) async {
    final filas =
        await (_deTienda(tienda)
              ..where((p) => p.codigo.equals(codigo))
              ..limit(1))
            .get();
    return filas.isEmpty ? null : MapeoProducto.aEntidad(filas.single);
  }

  /// TODO(CUS-17): buscar en `codigos_producto`. Sin esa tabla ningún producto
  /// tiene códigos asociados.
  @override
  Future<Producto?> buscarPorCodigoProducto(
    Tienda tienda,
    String valor,
  ) async => null;

  @override
  Future<List<Producto>> listar(Tienda tienda) async {
    final filas = await (_deTienda(
      tienda,
    )..orderBy([(p) => OrderingTerm.asc(p.nombreNormalizado)])).get();
    return filas.map(MapeoProducto.aEntidad).toList();
  }

  /// Crea o actualiza el producto y lo anota en `cola_pendientes` en la misma
  /// transacción (DA-33). Si ya hay una transacción abierta (unidad de trabajo),
  /// se une a ella.
  @override
  Future<void> guardar(Tienda tienda, Producto producto) =>
      _base.transaction(() async {
        final existe = await buscarPorId(tienda, producto.getId()) != null;
        await _base
            .into(_base.productos)
            .insertOnConflictUpdate(MapeoProducto.aFila(tienda, producto));
        await anotarEnCola(
          _base,
          tiendaId: tienda.getId(),
          tabla: _tabla,
          registroId: producto.getId(),
          operacion: existe ? OperacionCola.actualizar : OperacionCola.insertar,
        );
      });

  /// TODO(CUS-17 / CUS-22): sin `codigos_producto` no puede haber códigos
  /// repetidos.
  @override
  Future<List<CodigoProducto>> listarCodigosRepetidos(Tienda tienda) async =>
      const [];

  @override
  Future<Producto?> buscarPorId(Tienda tienda, String id) async {
    final fila = await (_deTienda(
      tienda,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    return fila == null ? null : MapeoProducto.aEntidad(fila);
  }

  static String _escaparLike(String texto) =>
      texto.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
}
