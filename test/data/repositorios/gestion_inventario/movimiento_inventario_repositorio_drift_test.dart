import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
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
      expect((await cola()).map((c) => (c.tabla, c.operacion)), [
        ('movimientos_inventario', 'INSERTAR'),
        ('items_inventario', 'ACTUALIZAR'),
      ]);
    });

    test(
      'si falla el guardado del ítem no queda nada (rollback real)',
      () async {
        final servicio = ServicioInventario(
          InventarioQueFallaAlGuardar(items),
          movimientos,
          d('5'),
          UnidadTrabajoDrift(base),
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
      },
    );
  });
}
