import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/ajuste_conteo.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_inventario_repositorio.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';

/// Lee con el repositorio real y falla al guardar el ítem, para probar el
/// rollback de la transacción de drift.
class InventarioQueFallaAlGuardar implements IInventarioRepositorio {
  InventarioQueFallaAlGuardar(this._real);

  final IInventarioRepositorio _real;

  @override
  Future<ItemInventario?> buscarItem(Tienda tienda, Producto producto) =>
      _real.buscarItem(tienda, producto);

  @override
  Future<List<ItemInventario>> listarItems(Tienda tienda) =>
      _real.listarItems(tienda);

  @override
  Future<void> guardarItem(Tienda tienda, ItemInventario item) =>
      throw StateError('falla del disco');
}

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otraTienda = Tienda('t2', 'T002', 'La Esquina', 'Turbaco');
  Decimal d(String v) => Decimal.parse(v);

  late BaseLocalDrift base;
  late InventarioRepositorioDrift items;
  late MovimientoInventarioRepositorioDrift movimientos;
  late Producto aceite;
  late ItemInventario item;

  setUp(() async {
    base = BaseLocalDrift(NativeDatabase.memory());
    items = InventarioRepositorioDrift(base);
    movimientos = MovimientoInventarioRepositorioDrift(base);
    aceite = Producto(
      'p1',
      'ACE-1',
      'Aceite 1 L',
      UnidadMedida.unidad,
      null,
      d('11000'),
    );
    await ProductoRepositorioDrift(base).guardar(tienda, aceite);
    item = ItemInventario('i1', aceite, d('8'));
    await items.guardarItem(tienda, item);
    await base.delete(base.colaPendientes).go();
  });
  tearDown(() => base.close());

  EntradaMercancia entrada(
    String id,
    DateTime fecha, {
    String costo = '8600',
    String? factura,
  }) => EntradaMercancia(id, item, d('24'), fecha, d(costo), factura);

  Future<List<FilaMovimientoInventario>> filas() =>
      base.select(base.movimientosInventario).get();

  Future<List<EntradaCola>> cola() => base.select(base.colaPendientes).get();

  Future<void> cambiarEstado(String id, String estado) => base.customStatement(
    'UPDATE movimientos_inventario SET estado = ? WHERE id = ?',
    [estado, id],
  );

  group('guardar', () {
    test('inserta la entrada con tipo, estado y decimales', () async {
      await movimientos.guardar(
        tienda,
        EntradaMercancia(
          'e1',
          item,
          d('2.375'),
          DateTime.utc(2026, 11, 2, 15),
          d('8600.50'),
          'FV-10231',
        ),
      );

      final fila = (await filas()).single;
      expect(fila.id, 'e1');
      expect(fila.tiendaId, 't1');
      expect(fila.itemId, 'i1');
      expect(fila.tipo, 'ENTRADA');
      expect(fila.estado, 'VIGENTE');
      expect(fila.cantidad, d('2.375'));
      expect(fila.costoUnitario, d('8600.50'));
      expect(fila.numeroFactura, 'FV-10231');
      expect(fila.fecha, DateTime.utc(2026, 11, 2, 15));
      expect(fila.fecha.isUtc, isTrue);
    });

    test('guarda nulo el número de factura que no llegó', () async {
      await movimientos.guardar(tienda, entrada('e1', DateTime.utc(2026)));
      expect((await filas()).single.numeroFactura, isNull);
    });

    test('anota INSERTAR en cola_pendientes con la tienda', () async {
      await movimientos.guardar(tienda, entrada('e1', DateTime.utc(2026)));
      final anotada = (await cola()).single;
      expect(anotada.tabla, 'movimientos_inventario');
      expect(anotada.registroId, 'e1');
      expect(anotada.operacion, 'INSERTAR');
      expect(anotada.tiendaId, 't1');
    });

    test('nunca reescribe un movimiento: el mismo id falla', () async {
      await movimientos.guardar(tienda, entrada('e1', DateTime.utc(2026)));
      await expectLater(
        movimientos.guardar(
          tienda,
          entrada('e1', DateTime.utc(2026), costo: '1'),
        ),
        throwsA(anything),
      );
      expect((await filas()).single.costoUnitario, d('8600'));
      expect(await cola(), hasLength(1));
    });
  });

  group('buscarUltimaEntrada', () {
    test('sin entradas devuelve nulo', () async {
      expect(await movimientos.buscarUltimaEntrada(item), isNull);
    });

    test('devuelve la más reciente por fecha', () async {
      await movimientos.guardar(
        tienda,
        entrada('e2', DateTime.utc(2026, 11, 2), costo: '8600'),
      );
      await movimientos.guardar(
        tienda,
        entrada('e1', DateTime.utc(2026, 10, 20), costo: '8000'),
      );

      final ultima = (await movimientos.buscarUltimaEntrada(item))!;
      expect(ultima.getId(), 'e2');
      expect(ultima.getCostoUnitario(), d('8600'));
      expect(ultima.getItem(), same(item));
      expect(ultima.getEstado(), EstadoMovimiento.vigente);
    });

    test('solo cuentan las VIGENTES', () async {
      await movimientos.guardar(
        tienda,
        entrada('e1', DateTime.utc(2026, 11, 2), costo: '8600'),
      );
      await movimientos.guardar(
        tienda,
        entrada('e2', DateTime.utc(2026, 11, 5), costo: '9400'),
      );
      await movimientos.guardar(
        tienda,
        entrada('e3', DateTime.utc(2026, 11, 6), costo: '9500'),
      );
      await cambiarEstado('e2', 'ANULADO');
      await cambiarEstado('e3', 'EN_REVISION');

      expect((await movimientos.buscarUltimaEntrada(item))!.getId(), 'e1');
    });

    test('no mezcla ítems ni tiendas', () async {
      final otroItem = ItemInventario('i2', aceite, Decimal.zero);
      await items.guardarItem(otraTienda, otroItem);
      await movimientos.guardar(
        otraTienda,
        EntradaMercancia(
          'e9',
          otroItem,
          d('1'),
          DateTime.utc(2026, 12),
          d('1'),
          null,
        ),
      );
      // Fila inconsistente: el ítem de t1 anotado en otra tienda.
      await movimientos.guardar(
        otraTienda,
        entrada('e8', DateTime.utc(2026, 12), costo: '1'),
      );
      await movimientos.guardar(
        tienda,
        entrada('e1', DateTime.utc(2026, 11), costo: '8600'),
      );

      expect((await movimientos.buscarUltimaEntrada(item))!.getId(), 'e1');
      expect((await movimientos.buscarUltimaEntrada(otroItem))!.getId(), 'e9');
    });
  });

  group('guardar una merma (CUS-03)', () {
    test('inserta tipo MERMA con cantidad negativa y su motivo', () async {
      await movimientos.guardar(
        tienda,
        Merma(
          'm1',
          item,
          d('-2.5'),
          DateTime.utc(2026, 11, 14, 9),
          MotivoMerma.devueltoProveedor,
        ),
      );

      final fila = (await filas()).single;
      expect(fila.id, 'm1');
      expect(fila.tiendaId, 't1');
      expect(fila.tipo, 'MERMA');
      expect(fila.estado, 'VIGENTE');
      expect(fila.cantidad, d('-2.5'));
      expect(fila.motivo, 'DEVUELTO_PROVEEDOR');
      expect(fila.costoUnitario, isNull);
      expect(fila.ventaId, isNull);
      final anotada = (await cola()).single;
      expect(
        (anotada.tabla, anotada.registroId, anotada.operacion),
        ('movimientos_inventario', 'm1', 'INSERTAR'),
      );
    });

    test('guarda cada motivo con su nombre del servidor', () async {
      var n = 0;
      for (final motivo in MotivoMerma.values) {
        await movimientos.guardar(
          tienda,
          Merma('m${n++}', item, d('-1'), DateTime.utc(2026), motivo),
        );
      }
      expect((await filas()).map((f) => f.motivo), [
        'VENCIDO',
        'DANADO',
        'DEVUELTO_PROVEEDOR',
        'OTRO',
      ]);
    });

    test('una merma no cuenta como última entrada', () async {
      await movimientos.guardar(
        tienda,
        Merma('m1', item, d('-1'), DateTime.utc(2026), MotivoMerma.otro),
      );
      expect(await movimientos.buscarUltimaEntrada(item), isNull);
    });
  });

  group('con ServicioInventario y UnidadTrabajoDrift', () {
    test('registrarMerma baja el stock y guarda el motivo', () async {
      final servicio = ServicioInventario(
        items,
        movimientos,
        d('5'),
        UnidadTrabajoDrift(base),
        ProductoRepositorioDrift(base),
      );

      final merma = await servicio.registrarMerma(
        tienda,
        aceite,
        d('3'),
        MotivoMerma.vencido,
      );

      expect(merma.getItem().getStockActual(), d('5'));
      expect(
        (await items.buscarItem(tienda, aceite))!.getStockActual(),
        d('5'),
      );
      final fila = (await filas()).single;
      expect(
        (fila.tipo, fila.cantidad, fila.motivo),
        ('MERMA', d('-3'), 'VENCIDO'),
      );
      expect((await cola()).map((c) => (c.tabla, c.operacion)), [
        ('movimientos_inventario', 'INSERTAR'),
        ('items_inventario', 'ACTUALIZAR'),
      ]);
    });

    test('registrarMerma mayor a la existencia no guarda nada', () async {
      final servicio = ServicioInventario(
        items,
        movimientos,
        d('5'),
        UnidadTrabajoDrift(base),
        ProductoRepositorioDrift(base),
      );

      await expectLater(
        servicio.registrarMerma(tienda, aceite, d('9'), MotivoMerma.danado),
        throwsA(isA<ExcepcionCantidadSuperaExistencia>()),
      );

      expect(await filas(), isEmpty);
      expect(await cola(), isEmpty);
      expect(
        (await items.buscarItem(tienda, aceite))!.getStockActual(),
        d('8'),
      );
    });

    test('registrarEntrada guarda movimiento, stock y cola juntos', () async {
      final servicio = ServicioInventario(
        items,
        movimientos,
        d('5'),
        UnidadTrabajoDrift(base),
        ProductoRepositorioDrift(base),
      );

      final nueva = await servicio.registrarEntrada(
        tienda,
        aceite,
        d('24'),
        d('9400'),
        null,
      );

      expect(nueva.getItem().getStockActual(), d('32'));
      expect(
        (await items.buscarItem(tienda, aceite))!.getStockActual(),
        d('32'),
      );
      expect((await filas()).single.id, nueva.getId());
      // El costo pasa a ser el precio de compra del producto (DI-33).
      expect((await cola()).map((c) => (c.tabla, c.operacion)), [
        ('productos', 'ACTUALIZAR'),
        ('movimientos_inventario', 'INSERTAR'),
        ('items_inventario', 'ACTUALIZAR'),
      ]);
      final guardado = await ProductoRepositorioDrift(base)
          .buscarPorId(tienda, aceite.getId());
      expect(guardado!.getPrecioCompra(), d('9400'));
      expect(guardado.getActualizadoEn(), aceite.getActualizadoEn());
    });

    test('una entrada con costo cero no cambia el precio de compra', () async {
      final servicio = ServicioInventario(
        items,
        movimientos,
        d('5'),
        UnidadTrabajoDrift(base),
        ProductoRepositorioDrift(base),
      );

      await servicio.registrarEntrada(tienda, aceite, d('2'), d('0'), null);

      expect((await cola()).map((c) => c.tabla), [
        'movimientos_inventario',
        'items_inventario',
      ]);
      expect(
        (await ProductoRepositorioDrift(
          base,
        ).buscarPorId(tienda, aceite.getId()))!.getPrecioCompra(),
        isNull,
      );
    });

    test(
      'si falla el guardado del ítem no queda nada (rollback real)',
      () async {
        final servicio = ServicioInventario(
          InventarioQueFallaAlGuardar(items),
          movimientos,
          d('5'),
          UnidadTrabajoDrift(base),
          ProductoRepositorioDrift(base),
        );

        await expectLater(
          servicio.registrarEntrada(tienda, aceite, d('24'), d('9400'), null),
          throwsStateError,
        );

        expect(await filas(), isEmpty);
        expect(await cola(), isEmpty);
        expect(
          (await items.buscarItem(tienda, aceite))!.getStockActual(),
          d('8'),
        );
        // El producto tampoco cambia, ni en la base ni en memoria (DI-33).
        expect(aceite.getPrecioCompra(), isNull);
        expect(
          (await ProductoRepositorioDrift(
            base,
          ).buscarPorId(tienda, aceite.getId()))!.getPrecioCompra(),
          isNull,
        );
      },
    );
  });
  group('conteo físico (CUS-04)', () {
    ServicioInventario servicioCon(IInventarioRepositorio repositorio) =>
        ServicioInventario(
          repositorio,
          movimientos,
          d('5'),
          UnidadTrabajoDrift(base),
          ProductoRepositorioDrift(base),
        );

    test('guarda AJUSTE_CONTEO con la diferencia y lo contado', () async {
      await movimientos.guardar(
        tienda,
        AjusteConteo(
          'a1',
          item,
          d('-2.5'),
          DateTime.utc(2026, 11, 14),
          d('5.5'),
        ),
      );

      final fila = (await filas()).single;
      expect(
        (fila.tipo, fila.cantidad, fila.cantidadContada, fila.estado),
        ('AJUSTE_CONTEO', d('-2.5'), d('5.5'), 'VIGENTE'),
      );
      expect(fila.motivo, isNull);
      expect((await cola()).single.registroId, 'a1');
    });

    for (final (contada, diferencia) in [
      ('11', '3'),
      ('2', '-6'),
      ('8', '0'),
    ]) {
      test('contada $contada: stock igual a lo contado, ajuste $diferencia y '
          'cola en la misma transacción', () async {
        final ajuste = await servicioCon(items)
            .registrarConteo(tienda, aceite, d(contada));

        expect(
          (await items.buscarItem(tienda, aceite))!.getStockActual(),
          d(contada),
        );
        final fila = (await filas()).single;
        expect(fila.id, ajuste.getId());
        expect(
          (fila.cantidad, fila.cantidadContada),
          (d(diferencia), d(contada)),
        );
        expect((await cola()).map((c) => (c.tabla, c.operacion)), [
          ('movimientos_inventario', 'INSERTAR'),
          ('items_inventario', 'ACTUALIZAR'),
        ]);
      });
    }

    test('cantidad negativa no guarda nada', () async {
      await expectLater(
        servicioCon(items).registrarConteo(tienda, aceite, d('-1')),
        throwsA(isA<ExcepcionCantidadContadaNegativa>()),
      );
      expect(await filas(), isEmpty);
      expect(await cola(), isEmpty);
    });

    test(
      'si falla el guardado del ítem no queda nada (rollback real)',
      () async {
        await expectLater(
          servicioCon(InventarioQueFallaAlGuardar(items))
              .registrarConteo(tienda, aceite, d('20')),
          throwsStateError,
        );

        expect(await filas(), isEmpty);
        expect(await cola(), isEmpty);
        expect(
          (await items.buscarItem(tienda, aceite))!.getStockActual(),
          d('8'),
        );
      },
    );
  });
  group('listarPorItem (CUS-25)', () {
    final desde = DateTime.utc(2026, 11, 1);
    final hasta = DateTime.utc(2026, 11, 8);

    Future<void> venta(String id, DateTime fecha) async {
      await base
          .into(base.ventas)
          .insert(
            VentasCompanion.insert(
              id: 'v$id',
              tiendaId: tienda.getId(),
              fecha: fecha,
              total: d('22000'),
            ),
          );
      await movimientos.guardar(
        tienda,
        SalidaVenta(id, item, d('-2'), fecha, 'v$id', d('11000'), d('8600')),
      );
    }

    test('lee los cuatro tipos con sus datos, del más reciente al más '
        'antiguo', () async {
      await movimientos.guardar(
        tienda,
        entrada('e1', DateTime.utc(2026, 11, 2), factura: 'FV-10231'),
      );
      await venta('s1', DateTime.utc(2026, 11, 3));
      await movimientos.guardar(
        tienda,
        Merma(
          'm1',
          item,
          d('-1'),
          DateTime.utc(2026, 11, 4),
          MotivoMerma.devueltoProveedor,
        ),
      );
      await movimientos.guardar(
        tienda,
        AjusteConteo(
          'a1',
          item,
          d('-0.5'),
          DateTime.utc(2026, 11, 5),
          d('28.5'),
        ),
      );

      final lista = await movimientos.listarPorItem(item, desde, hasta);

      expect(lista.map((m) => m.getId()), ['a1', 'm1', 's1', 'e1']);
      final ajuste = lista[0] as AjusteConteo;
      expect(ajuste.getCantidad(), d('-0.5'));
      expect(ajuste.getCantidadContada(), d('28.5'));
      expect((lista[1] as Merma).getMotivo(), MotivoMerma.devueltoProveedor);
      final salida = lista[2] as SalidaVenta;
      expect(salida.getCantidad(), d('-2'));
      expect(salida.getVentaId(), 'vs1');
      expect(salida.getPrecioUnitario(), d('11000'));
      final e = lista[3] as EntradaMercancia;
      expect(e.getCantidad(), d('24'));
      expect(e.getNumeroFactura(), 'FV-10231');
      expect(e.getFecha(), DateTime.utc(2026, 11, 2));
      expect(e.getFecha().isUtc, isTrue);
      expect(lista.every((m) => identical(m.getItem(), item)), isTrue);
    });

    test('trae cada movimiento con su estado guardado', () async {
      await movimientos.guardar(
        tienda,
        entrada('vig', DateTime.utc(2026, 11, 2)),
      );
      await movimientos.guardar(
        tienda,
        entrada('rev', DateTime.utc(2026, 11, 3)),
      );
      await movimientos.guardar(
        tienda,
        entrada('anu', DateTime.utc(2026, 11, 4)),
      );
      await cambiarEstado('rev', 'EN_REVISION');
      await cambiarEstado('anu', 'ANULADO');

      final lista = await movimientos.listarPorItem(item, desde, hasta);

      expect(
        {for (final m in lista) m.getId(): m.getEstado()},
        {
          'anu': EstadoMovimiento.anulado,
          'rev': EstadoMovimiento.enRevision,
          'vig': EstadoMovimiento.vigente,
        },
      );
    });

    test('el periodo incluye "desde" y excluye "hasta"', () async {
      await movimientos.guardar(tienda, entrada('desde', desde));
      await movimientos.guardar(tienda, entrada('hasta', hasta));
      await movimientos.guardar(
        tienda,
        entrada('antes', desde.subtract(const Duration(seconds: 1))),
      );

      final lista = await movimientos.listarPorItem(item, desde, hasta);

      expect(lista.map((m) => m.getId()), ['desde']);
    });

    test('compara en UTC aunque el periodo llegue en hora local', () async {
      await movimientos.guardar(
        tienda,
        entrada('e1', DateTime.utc(2026, 11, 3)),
      );

      final lista = await movimientos.listarPorItem(
        item,
        desde.toLocal(),
        hasta.toLocal(),
      );

      expect(lista.map((m) => m.getId()), ['e1']);
    });

    test('no mezcla ítems ni tiendas', () async {
      final arroz = Producto(
        'p2',
        'ARR-1',
        'Arroz 500 g',
        UnidadMedida.unidad,
        null,
        d('2800'),
      );
      await ProductoRepositorioDrift(base).guardar(tienda, arroz);
      final itemArroz = ItemInventario('i2', arroz, d('5'));
      await items.guardarItem(tienda, itemArroz);
      await movimientos.guardar(
        tienda,
        EntradaMercancia('de-arroz', itemArroz, d('5'), desde, d('2000'), null),
      );
      await movimientos.guardar(tienda, entrada('del-aceite', desde));
      // Una fila con el mismo ítem pero de otra tienda no es de este ítem.
      await movimientos.guardar(otraTienda, entrada('otra-tienda', desde));

      final lista = await movimientos.listarPorItem(item, desde, hasta);

      expect(lista.map((m) => m.getId()), ['del-aceite']);
    });

    test('sin movimientos en el periodo devuelve una lista vacía', () async {
      expect(await movimientos.listarPorItem(item, desde, hasta), isEmpty);
    });
  });
}
