import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:gip/business/entidades/gestion_inventario/ajuste_conteo.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/mapeo_producto.dart';

/// [IMovimientoInventarioRepositorio] sobre la base local (drift), en la tabla
/// única `movimientos_inventario` con columna `tipo` (DI-03). Los movimientos
/// solo se agregan (RNF-15). Maneja ENTRADA (CUS-01), SALIDA_VENTA (CUS-02),
/// MERMA (CUS-03) y AJUSTE_CONTEO (CUS-04) (DI-20, DI-21, DI-22, DI-24); el
/// historial de un ítem los lee todos (CUS-25, DI-32).
class MovimientoInventarioRepositorioDrift
    implements IMovimientoInventarioRepositorio {
  MovimientoInventarioRepositorioDrift(this._base);

  final BaseLocalDrift _base;

  static const _tabla = 'movimientos_inventario';
  static const _tipoEntrada = 'ENTRADA';
  static const _tipoSalidaVenta = 'SALIDA_VENTA';
  static const _tipoMerma = 'MERMA';
  static const _tipoAjusteConteo = 'AJUSTE_CONTEO';

  /// Nombres que comparte con el enum `motivo_merma` de Supabase.
  static const _motivos = {
    MotivoMerma.vencido: 'VENCIDO',
    MotivoMerma.danado: 'DANADO',
    MotivoMerma.devueltoProveedor: 'DEVUELTO_PROVEEDOR',
    MotivoMerma.otro: 'OTRO',
  };

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
      SalidaVenta() => MovimientosInventarioCompanion.insert(
        id: movimiento.getId(),
        tiendaId: tienda.getId(),
        itemId: movimiento.getItem().getId(),
        tipo: _tipoSalidaVenta,
        cantidad: movimiento.getCantidad(),
        fecha: movimiento.getFecha(),
        estado: _estados[movimiento.getEstado()]!,
        costoUnitario: Value(movimiento.getCostoUnitario()),
        ventaId: Value(movimiento.getVenta().getId()),
        precioUnitario: Value(movimiento.getPrecioUnitario()),
      ),
      Merma() => MovimientosInventarioCompanion.insert(
        id: movimiento.getId(),
        tiendaId: tienda.getId(),
        itemId: movimiento.getItem().getId(),
        tipo: _tipoMerma,
        cantidad: movimiento.getCantidad(),
        fecha: movimiento.getFecha(),
        estado: _estados[movimiento.getEstado()]!,
        motivo: Value(_motivos[movimiento.getMotivo()]!),
      ),
      AjusteConteo() => MovimientosInventarioCompanion.insert(
        id: movimiento.getId(),
        tiendaId: tienda.getId(),
        itemId: movimiento.getItem().getId(),
        tipo: _tipoAjusteConteo,
        cantidad: movimiento.getCantidad(),
        fecha: movimiento.getFecha(),
        estado: _estados[movimiento.getEstado()]!,
        cantidadContada: Value(movimiento.getCantidadContada()),
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

  /// Salidas VIGENTES por venta del ítem con fecha en `[desde, hasta)` (DI-25).
  /// La tienda sale del ítem, como en [buscarUltimaEntrada]. La venta de cada
  /// salida trae solo id, fecha y total, sin formas de pago: el consumo no las
  /// necesita. Hasta CUS-20 no hay ventas anuladas que descartar.
  @override
  Future<List<SalidaVenta>> listarSalidas(
    ItemInventario item,
    DateTime desde,
    DateTime hasta,
  ) async {
    final m = _base.movimientosInventario;
    final i = _base.itemsInventario;
    final v = _base.ventas;
    final consulta =
        _base.select(m).join([
            innerJoin(
              i,
              i.id.equalsExp(m.itemId) & i.tiendaId.equalsExp(m.tiendaId),
              useColumns: false,
            ),
            leftOuterJoin(v, v.id.equalsExp(m.ventaId)),
          ])
          ..where(
            m.itemId.equals(item.getId()) &
                m.tipo.equals(_tipoSalidaVenta) &
                m.estado.equals(_estados[EstadoMovimiento.vigente]!) &
                m.fecha.isBiggerOrEqualValue(desde.toUtc()) &
                m.fecha.isSmallerThanValue(hasta.toUtc()),
          )
          ..orderBy([OrderingTerm.desc(m.fecha)]);
    final resultado = await consulta.get();
    return [
      for (final r in resultado)
        _salida(r.readTable(m), r.readTableOrNull(v), item),
    ];
  }

  /// Salidas VIGENTES por venta de la tienda con fecha en `[desde, hasta)`
  /// (CUS-09, DI-28). Cada ítem y producto se arma una sola vez y lo comparten
  /// las salidas del mismo ítem.
  @override
  Future<List<SalidaVenta>> listarSalidasPorTienda(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async {
    final m = _base.movimientosInventario;
    final i = _base.itemsInventario;
    final p = _base.productos;
    final v = _base.ventas;
    final consulta =
        _base.select(m).join([
            innerJoin(
              i,
              i.id.equalsExp(m.itemId) & i.tiendaId.equalsExp(m.tiendaId),
            ),
            innerJoin(p, p.id.equalsExp(i.productoId)),
            leftOuterJoin(v, v.id.equalsExp(m.ventaId)),
          ])
          ..where(
            m.tiendaId.equals(tienda.getId()) &
                m.tipo.equals(_tipoSalidaVenta) &
                m.estado.equals(_estados[EstadoMovimiento.vigente]!) &
                m.fecha.isBiggerOrEqualValue(desde.toUtc()) &
                m.fecha.isSmallerThanValue(hasta.toUtc()),
          )
          ..orderBy([OrderingTerm.asc(m.fecha)]);
    final items = <String, ItemInventario>{};
    return [
      for (final r in await consulta.get())
        _salida(
          r.readTable(m),
          r.readTableOrNull(v),
          items.putIfAbsent(r.readTable(i).id, () {
            final fila = r.readTable(i);
            return ItemInventario(
              fila.id,
              MapeoProducto.aEntidad(r.readTable(p)),
              fila.stockActual,
            );
          }),
        ),
    ];
  }

  SalidaVenta _salida(
    FilaMovimientoInventario fila,
    FilaVenta? venta,
    ItemInventario item,
  ) => SalidaVenta(
    fila.id,
    item,
    fila.cantidad,
    fila.fecha,
    Venta(
      fila.ventaId ?? '',
      const [],
      venta?.total ?? Decimal.zero,
      venta?.fecha ?? fila.fecha,
    ),
    fila.precioUnitario ?? Decimal.zero,
    fila.costoUnitario,
  );

  /// Salidas por venta de las [ventas] dadas, en cualquier estado, con su
  /// ítem (stock actual) y su producto (CUS-20, DI-39). Cada ítem se arma una
  /// sola vez y lo comparten las salidas del mismo ítem, para que anular varias
  /// salidas de un mismo ítem sume sobre el mismo stock. Toda consulta filtra
  /// por `tienda_id`.
  @override
  Future<List<SalidaVenta>> listarSalidasPorVentas(
    Tienda tienda,
    List<Venta> ventas,
  ) async {
    if (ventas.isEmpty) return const [];
    final porId = {for (final v in ventas) v.getId(): v};
    final m = _base.movimientosInventario;
    final i = _base.itemsInventario;
    final p = _base.productos;
    final consulta =
        _base.select(m).join([
            innerJoin(
              i,
              i.id.equalsExp(m.itemId) & i.tiendaId.equalsExp(m.tiendaId),
            ),
            innerJoin(p, p.id.equalsExp(i.productoId)),
          ])
          ..where(
            m.tiendaId.equals(tienda.getId()) &
                m.tipo.equals(_tipoSalidaVenta) &
                m.ventaId.isIn(porId.keys.toList()),
          )
          ..orderBy([OrderingTerm.asc(m.fecha)]);
    final items = <String, ItemInventario>{};
    final estados = _estados.map((k, v) => MapEntry(v, k));
    return [
      for (final r in await consulta.get())
        _salidaDeVenta(
          r.readTable(m),
          porId[r.readTable(m).ventaId]!,
          items.putIfAbsent(r.readTable(i).id, () {
            final fila = r.readTable(i);
            return ItemInventario(
              fila.id,
              MapeoProducto.aEntidad(r.readTable(p)),
              fila.stockActual,
            );
          }),
          estados[r.readTable(m).estado]!,
        ),
    ];
  }

  SalidaVenta _salidaDeVenta(
    FilaMovimientoInventario fila,
    Venta venta,
    ItemInventario item,
    EstadoMovimiento estado,
  ) => SalidaVenta(
    fila.id,
    item,
    fila.cantidad,
    fila.fecha,
    venta,
    fila.precioUnitario ?? Decimal.zero,
    fila.costoUnitario,
  )..setEstado(estado);

  /// Movimientos de la tienda con esos ids, de cualquier tipo y en cualquier
  /// estado, cada uno con su ítem (stock actual) y su producto (CUS-22,
  /// DI-45). Cada ítem se arma una sola vez y lo comparten los movimientos del
  /// mismo ítem, para recalcular el stock una vez por ítem. La venta de cada
  /// salida trae solo id, fecha y total. Toda consulta filtra por `tienda_id`.
  @override
  Future<List<MovimientoInventario>> buscarPorIds(
    Tienda tienda,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const [];
    final m = _base.movimientosInventario;
    final i = _base.itemsInventario;
    final p = _base.productos;
    final v = _base.ventas;
    final consulta =
        _base.select(m).join([
            innerJoin(
              i,
              i.id.equalsExp(m.itemId) & i.tiendaId.equalsExp(m.tiendaId),
            ),
            innerJoin(p, p.id.equalsExp(i.productoId)),
            leftOuterJoin(v, v.id.equalsExp(m.ventaId)),
          ])
          ..where(m.tiendaId.equals(tienda.getId()) & m.id.isIn(ids))
          ..orderBy([OrderingTerm.asc(m.fecha), OrderingTerm.asc(m.id)]);
    final items = <String, ItemInventario>{};
    return [
      for (final r in await consulta.get())
        _movimiento(
          r.readTable(m),
          r.readTableOrNull(v),
          items.putIfAbsent(r.readTable(i).id, () {
            final fila = r.readTable(i);
            return ItemInventario(
              fila.id,
              MapeoProducto.aEntidad(r.readTable(p)),
              fila.stockActual,
            );
          }),
        ),
    ];
  }

  /// Guarda solo el estado del movimiento y lo anota en `cola_pendientes` como
  /// ACTUALIZAR en la misma transacción (DA-33, RNF-15); no toca lo demás. Se
  /// une a la transacción abierta.
  @override
  Future<void> actualizarEstado(
    Tienda tienda,
    MovimientoInventario movimiento,
  ) => _base.transaction(() async {
    await (_base.update(_base.movimientosInventario)..where(
          (m) =>
              m.id.equals(movimiento.getId()) &
              m.tiendaId.equals(tienda.getId()),
        ))
        .write(
          MovimientosInventarioCompanion(
            estado: Value(_estados[movimiento.getEstado()]!),
          ),
        );
    await anotarEnCola(
      _base,
      tiendaId: tienda.getId(),
      tabla: _tabla,
      registroId: movimiento.getId(),
      operacion: OperacionCola.actualizar,
    );
  });

  /// Entradas VIGENTES de la tienda con fecha en `[desde, hasta)` (CUS-10,
  /// DI-29). Cada ítem y producto se arma una sola vez.
  @override
  Future<List<EntradaMercancia>> listarEntradasPorTienda(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async {
    final m = _base.movimientosInventario;
    final i = _base.itemsInventario;
    final p = _base.productos;
    final consulta =
        _base.select(m).join([
            innerJoin(
              i,
              i.id.equalsExp(m.itemId) & i.tiendaId.equalsExp(m.tiendaId),
            ),
            innerJoin(p, p.id.equalsExp(i.productoId)),
          ])
          ..where(
            m.tiendaId.equals(tienda.getId()) &
                m.tipo.equals(_tipoEntrada) &
                m.estado.equals(_estados[EstadoMovimiento.vigente]!) &
                m.fecha.isBiggerOrEqualValue(desde.toUtc()) &
                m.fecha.isSmallerThanValue(hasta.toUtc()),
          )
          ..orderBy([OrderingTerm.asc(m.fecha)]);
    final items = <String, ItemInventario>{};
    return [
      for (final r in await consulta.get())
        EntradaMercancia(
          r.readTable(m).id,
          items.putIfAbsent(r.readTable(i).id, () {
            final fila = r.readTable(i);
            return ItemInventario(
              fila.id,
              MapeoProducto.aEntidad(r.readTable(p)),
              fila.stockActual,
            );
          }),
          r.readTable(m).cantidad,
          r.readTable(m).fecha,
          r.readTable(m).costoUnitario ?? Decimal.zero,
          r.readTable(m).numeroFactura,
        )..setEstado(EstadoMovimiento.vigente),
    ];
  }

  /// Historial del ítem con fecha en `[desde, hasta)`, del más reciente al más
  /// antiguo, de los cuatro tipos y en cualquier estado (CUS-25, DI-32). La
  /// tienda sale del ítem, como en [buscarUltimaEntrada]. La venta de cada
  /// salida trae solo id, fecha y total, como en [listarSalidas].
  @override
  Future<List<MovimientoInventario>> listarPorItem(
    ItemInventario item,
    DateTime desde,
    DateTime hasta,
  ) async {
    final m = _base.movimientosInventario;
    final i = _base.itemsInventario;
    final v = _base.ventas;
    final consulta =
        _base.select(m).join([
            innerJoin(
              i,
              i.id.equalsExp(m.itemId) & i.tiendaId.equalsExp(m.tiendaId),
              useColumns: false,
            ),
            leftOuterJoin(v, v.id.equalsExp(m.ventaId)),
          ])
          ..where(
            m.itemId.equals(item.getId()) &
                m.fecha.isBiggerOrEqualValue(desde.toUtc()) &
                m.fecha.isSmallerThanValue(hasta.toUtc()),
          )
          ..orderBy([OrderingTerm.desc(m.fecha), OrderingTerm.desc(m.id)]);
    return [
      for (final r in await consulta.get())
        _movimiento(r.readTable(m), r.readTableOrNull(v), item),
    ];
  }

  /// Arma la subclase según `tipo` y le pone el estado guardado.
  MovimientoInventario _movimiento(
    FilaMovimientoInventario fila,
    FilaVenta? venta,
    ItemInventario item,
  ) {
    final MovimientoInventario movimiento = switch (fila.tipo) {
      _tipoEntrada => EntradaMercancia(
        fila.id,
        item,
        fila.cantidad,
        fila.fecha,
        fila.costoUnitario ?? Decimal.zero,
        fila.numeroFactura,
      ),
      _tipoSalidaVenta => _salida(fila, venta, item),
      _tipoMerma => Merma(
        fila.id,
        item,
        fila.cantidad,
        fila.fecha,
        _motivos.entries.firstWhere((e) => e.value == fila.motivo).key,
      ),
      _tipoAjusteConteo => AjusteConteo(
        fila.id,
        item,
        fila.cantidad,
        fila.fecha,
        fila.cantidadContada ?? Decimal.zero,
      ),
      _ => throw StateError('Tipo de movimiento desconocido: ${fila.tipo}'),
    };
    return movimiento..setEstado(
      _estados.entries.firstWhere((e) => e.value == fila.estado).key,
    );
  }

  /// Fecha del primer movimiento del ítem, de cualquier tipo y estado (DI-25).
  @override
  Future<DateTime?> buscarFechaPrimerMovimiento(ItemInventario item) async {
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
          ..where(m.itemId.equals(item.getId()))
          ..orderBy([OrderingTerm.asc(m.fecha)])
          ..limit(1);
    return (await consulta.getSingleOrNull())?.readTable(m).fecha;
  }
}
