import 'package:drift/drift.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/data/local/base_local_drift.dart';

/// [IMovimientoInventarioRepositorio] sobre la base local (drift), en la tabla
/// única `movimientos_inventario` con columna `tipo` (DI-03). Los movimientos
/// solo se agregan (RNF-15). Por ahora solo maneja ENTRADA (CUS-01); los
/// demás tipos llegan con su caso de uso (DI-20).
class MovimientoInventarioRepositorioDrift
    implements IMovimientoInventarioRepositorio {
  MovimientoInventarioRepositorioDrift(this._base);

  final BaseLocalDrift _base;

  static const _tabla = 'movimientos_inventario';
  static const _tipoEntrada = 'ENTRADA';

  /// Nombres que comparte con el enum `estado_movimiento` de Supabase.
  static const _estados = {
    EstadoMovimiento.vigente: 'VIGENTE',
    EstadoMovimiento.enRevision: 'EN_REVISION',
    EstadoMovimiento.anulado: 'ANULADO',
  };

  /// Inserta el movimiento (nunca lo reescribe) y lo anota en
  /// `cola_pendientes` en la misma transacción (DA-33); se une a la
  /// transacción abierta si la hay.
  @override
  Future<void> guardar(Tienda tienda, MovimientoInventario movimiento) {
    final fila = switch (movimiento) {
      EntradaMercancia() => MovimientosInventarioCompanion.insert(
        id: movimiento.getId(),
        tiendaId: tienda.getId(),
        itemId: movimiento.getItem().getId(),
        tipo: _tipoEntrada,
        cantidad: movimiento.getCantidad(),
        fecha: movimiento.getFecha(),
        estado: _estados[movimiento.getEstado()]!,
        costoUnitario: Value(movimiento.getCostoUnitario()),
        numeroFactura: Value(movimiento.getNumeroFactura()),
      ),
      _ => throw UnsupportedError(
        'Tipo de movimiento no disponible todavía: ${movimiento.runtimeType}',
      ),
    };
    return _base.transaction(() async {
      await _base.into(_base.movimientosInventario).insert(fila);
      await anotarEnCola(
        _base,
        tiendaId: tienda.getId(),
        tabla: _tabla,
        registroId: movimiento.getId(),
        operacion: OperacionCola.insertar,
      );
    });
  }

  /// Última entrada VIGENTE del ítem por fecha (DI-20). La tienda sale del
  /// ítem: la consulta se une con `items_inventario` por id y `tienda_id`.
  @override
  Future<EntradaMercancia?> buscarUltimaEntrada(ItemInventario item) async {
    final m = _base.movimientosInventario;
    final i = _base.itemsInventario;
    final consulta =
        _base.select(m).join([
            innerJoin(
              i,
              i.id.equalsExp(m.itemId) & i.tiendaId.equalsExp(m.tiendaId),
              useColumns: false,
            ),
          ])
          ..where(
            m.itemId.equals(item.getId()) &
                m.tipo.equals(_tipoEntrada) &
                m.estado.equals(_estados[EstadoMovimiento.vigente]!),
          )
          ..orderBy([OrderingTerm.desc(m.fecha)])
          ..limit(1);
    final fila = (await consulta.getSingleOrNull())?.readTable(m);
    if (fila == null) return null;
    return EntradaMercancia(
      fila.id,
      item,
      fila.cantidad,
      fila.fecha,
      fila.costoUnitario!,
      fila.numeroFactura,
    )..setEstado(EstadoMovimiento.vigente);
  }
}
