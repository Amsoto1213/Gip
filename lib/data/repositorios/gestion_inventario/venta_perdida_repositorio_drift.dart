import 'package:drift/drift.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_venta_perdida_repositorio.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/mapeo_producto.dart';

/// [IVentaPerdidaRepositorio] sobre la base local (drift), tabla
/// `ventas_perdidas`. Solo agrega (RNF-15, DI-30). Los periodos son
/// `[desde, hasta)`.
class VentaPerdidaRepositorioDrift implements IVentaPerdidaRepositorio {
  VentaPerdidaRepositorioDrift(this._base);

  static const _tabla = 'ventas_perdidas';

  final BaseLocalDrift _base;

  /// Inserta la fila (nunca la reemplaza: un id repetido falla) y la anota en
  /// `cola_pendientes` en la misma transacción (DA-33).
  @override
  Future<void> guardar(Tienda tienda, VentaPerdida ventaPerdida) =>
      _base.transaction(() async {
        await _base
            .into(_base.ventasPerdidas)
            .insert(
              VentasPerdidasCompanion.insert(
                id: ventaPerdida.getId(),
                tiendaId: tienda.getId(),
                productoId: ventaPerdida.getProductoId(),
                fecha: ventaPerdida.getFecha().toUtc(),
              ),
            );
        await anotarEnCola(
          _base,
          tiendaId: tienda.getId(),
          tabla: _tabla,
          registroId: ventaPerdida.getId(),
          operacion: OperacionCola.insertar,
        );
      });

  /// Ventas perdidas de la tienda en el periodo, con su producto, de la más
  /// reciente a la más antigua.
  @override
  Future<List<VentaPerdida>> buscarPorPeriodo(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async {
    final v = _base.ventasPerdidas;
    final p = _base.productos;
    final consulta =
        _base.select(v).join([innerJoin(p, p.id.equalsExp(v.productoId))])
          ..where(
            v.tiendaId.equals(tienda.getId()) &
                v.fecha.isBiggerOrEqualValue(desde.toUtc()) &
                v.fecha.isSmallerThanValue(hasta.toUtc()),
          )
          ..orderBy([OrderingTerm.desc(v.fecha)]);
    return [
      for (final f in await consulta.get())
        VentaPerdida(
          f.readTable(v).id,
          MapeoProducto.aEntidad(f.readTable(p)),
          f.readTable(v).fecha,
        ),
    ];
  }

  /// Ventas perdidas del producto en el periodo. La tienda sale del producto
  /// (como `buscarUltimaEntrada`, DI-20): se filtra por su id y su tienda.
  @override
  Future<List<VentaPerdida>> listarPorProducto(
    Producto producto,
    DateTime desde,
    DateTime hasta,
  ) async {
    final v = _base.ventasPerdidas;
    final p = _base.productos;
    final consulta =
        _base.select(v).join([
            innerJoin(
              p,
              p.id.equalsExp(v.productoId) & p.tiendaId.equalsExp(v.tiendaId),
              useColumns: false,
            ),
          ])
          ..where(
            v.productoId.equals(producto.getId()) &
                v.fecha.isBiggerOrEqualValue(desde.toUtc()) &
                v.fecha.isSmallerThanValue(hasta.toUtc()),
          )
          ..orderBy([OrderingTerm.desc(v.fecha)]);
    return [
      for (final f in await consulta.get())
        VentaPerdida(f.readTable(v).id, producto, f.readTable(v).fecha),
    ];
  }
}
