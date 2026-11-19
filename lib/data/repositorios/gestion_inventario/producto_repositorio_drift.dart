import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_producto_repositorio.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/transversal/texto/normalizar_texto.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/mapeo_producto.dart';

/// [IProductoRepositorio] sobre la base local (drift). Toda consulta filtra por
/// `tienda_id`. Los productos se leen con sus códigos de barras o QR
/// (`codigos_producto`, CUS-17).
class ProductoRepositorioDrift implements IProductoRepositorio {
  ProductoRepositorioDrift(this._base);

  final BaseLocalDrift _base;

  static const _tabla = 'productos';
  static const _tablaCodigos = 'codigos_producto';

  SimpleSelectStatement<$ProductosTable, FilaProducto> _deTienda(
    Tienda tienda,
  ) =>
      _base.select(_base.productos)
        ..where((p) => p.tiendaId.equals(tienda.getId()));

  /// Convierte las filas en productos con sus códigos, en el orden de
  /// asociación. Una sola consulta para todos los productos.
  Future<List<Producto>> _conCodigos(List<FilaProducto> filas) async {
    if (filas.isEmpty) return const [];
    final codigos =
        await (_base.select(_base.codigosProducto)
              ..where((c) => c.productoId.isIn(filas.map((f) => f.id)))
              ..orderBy([
                (c) => OrderingTerm.asc(c.creadoEn),
                (c) => OrderingTerm.asc(c.id),
              ]))
            .get();
    final porProducto = groupBy(
      codigos,
      (FilaCodigoProducto c) => c.productoId,
    );
    return [
      for (final f in filas)
        MapeoProducto.aEntidad(f, codigos: porProducto[f.id] ?? const []),
    ];
  }

  Future<Producto?> _unoConCodigos(FilaProducto? fila) async =>
      fila == null ? null : (await _conCodigos([fila])).single;

  @override
  Future<List<Producto>> buscarPorNombre(Tienda tienda, String texto) async {
    final patron = '%${_escaparLike(normalizarTexto(texto))}%';
    final filas =
        await (_deTienda(tienda)
              ..where((p) => p.nombreNormalizado.like(patron, escapeChar: r'\'))
              ..orderBy([(p) => OrderingTerm.asc(p.nombreNormalizado)]))
            .get();
    return _conCodigos(filas);
  }

  @override
  Future<Producto?> buscarPorCodigo(Tienda tienda, String codigo) async {
    final filas =
        await (_deTienda(tienda)
              ..where((p) => p.codigo.equals(codigo))
              ..limit(1))
            .get();
    return _unoConCodigos(filas.firstOrNull);
  }

  /// Compara el texto exacto de la lectura (mayúsculas y prefijos incluidos)
  /// con los códigos de la tienda (DA-41). Si tras sincronizar un valor quedó
  /// en dos productos (CUS-22), devuelve el del código asociado primero.
  @override
  Future<Producto?> buscarPorCodigoProducto(Tienda tienda, String valor) async {
    final c = _base.codigosProducto;
    final consulta =
        _base.select(_base.productos).join([
            innerJoin(c, c.productoId.equalsExp(_base.productos.id)),
          ])
          ..where(
            c.tiendaId.equals(tienda.getId()) &
                _base.productos.tiendaId.equals(tienda.getId()) &
                c.valor.equals(valor),
          )
          ..orderBy([OrderingTerm.asc(c.creadoEn), OrderingTerm.asc(c.id)])
          ..limit(1);
    final fila = await consulta.getSingleOrNull();
    return _unoConCodigos(fila?.readTable(_base.productos));
  }

  @override
  Future<List<Producto>> listar(Tienda tienda) async {
    final filas = await (_deTienda(
      tienda,
    )..orderBy([(p) => OrderingTerm.asc(p.nombreNormalizado)])).get();
    return _conCodigos(filas);
  }

  /// Crea o actualiza el producto y agrega los códigos que todavía no estén
  /// guardados; cada escritura se anota en `cola_pendientes` en la misma
  /// transacción (DA-33). Si ya hay una transacción abierta (unidad de
  /// trabajo), se une a ella.
  ///
  /// Nunca borra códigos: un producto leído por otro repositorio llega sin
  /// ellos. Quitar un código (CUS-22, `quitarCodigo`) llega con su caso de
  /// uso (DI-34).
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
        await _agregarCodigosNuevos(tienda, producto);
      });

  Future<void> _agregarCodigosNuevos(Tienda tienda, Producto producto) async {
    final guardados =
        (await (_base.selectOnly(_base.codigosProducto)
                  ..addColumns([_base.codigosProducto.id])
                  ..where(
                    _base.codigosProducto.productoId.equals(producto.getId()),
                  ))
                .map((f) => f.read(_base.codigosProducto.id)!)
                .get())
            .toSet();
    for (final codigo in producto.getCodigos()) {
      if (guardados.contains(codigo.getId())) continue;
      await _base
          .into(_base.codigosProducto)
          .insert(MapeoProducto.codigoAFila(tienda, producto, codigo));
      await anotarEnCola(
        _base,
        tiendaId: tienda.getId(),
        tabla: _tablaCodigos,
        registroId: codigo.getId(),
        operacion: OperacionCola.insertar,
      );
    }
  }

  /// TODO(CUS-22): códigos cuyo valor quedó en más de un producto al
  /// sincronizar. Sin sincronización todavía no puede pasar: la regla de no
  /// repetir la valida `ServicioCatalogo.asociarCodigo`.
  @override
  Future<List<CodigoProducto>> listarCodigosRepetidos(Tienda tienda) async =>
      const [];

  @override
  Future<Producto?> buscarPorId(Tienda tienda, String id) async {
    final fila = await (_deTienda(
      tienda,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    return _unoConCodigos(fila);
  }

  /// Borra el código del producto y anota el borrado en `cola_pendientes` como
  /// ELIMINAR en la misma transacción (DA-33). Es la única operación que quita
  /// un código: [guardar] nunca lo hace (DI-34, CUS-22, DI-45). Se une a la
  /// transacción abierta.
  @override
  Future<void> quitarCodigo(
    Tienda tienda,
    Producto producto,
    CodigoProducto codigo,
  ) => _base.transaction(() async {
    final borradas =
        await (_base.delete(_base.codigosProducto)..where(
              (c) =>
                  c.id.equals(codigo.getId()) &
                  c.tiendaId.equals(tienda.getId()) &
                  c.productoId.equals(producto.getId()),
            ))
            .go();
    if (borradas == 0) return;
    await anotarEnCola(
      _base,
      tiendaId: tienda.getId(),
      tabla: _tablaCodigos,
      registroId: codigo.getId(),
      operacion: OperacionCola.eliminar,
    );
  });

  static String _escaparLike(String texto) =>
      texto.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
}
