import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_movimientos.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/transversal/errores/errores_conciliacion.dart';

import '../gestion_inventario/fakes_catalogo.dart';
import '../gestion_inventario/fakes_inventario.dart';

/// ResolutorMovimientos (CUS-22, DA-66, DI-45): POSIBLE_DUPLICADO y
/// STOCK_NEGATIVO anulan movimientos de inventario y recalculan el stock.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otra = Tienda('t2', 'T002', 'Tienda Dos', 'Turbaco');
  Decimal d(String v) => Decimal.parse(v);
  final fecha = DateTime.utc(2026, 11, 19, 15, 42);

  late InventarioRepositorioFalso items;
  late MovimientoRepositorioFalso movimientos;
  late ResolutorMovimientos resolutor;
  late ItemInventario huevo;
  late ItemInventario arroz;
  var n = 0;

  setUp(() async {
    n = 0;
    items = InventarioRepositorioFalso();
    movimientos = MovimientoRepositorioFalso();
    final productos = ProductoRepositorioFalso();
    final unidad = UnidadTrabajoFalsa([items, movimientos, productos]);
    final servicioInventario = ServicioInventario(
      items,
      movimientos,
      d('5'),
      unidad,
      productos,
    );
    resolutor = ResolutorMovimientos(movimientos, servicioInventario);
    huevo = ItemInventario(
      'i1',
      Producto('p1', 'H1', 'Huevo AA', UnidadMedida.unidad, d('400'), d('550')),
      // El stock de antes de unir los equipos.
      d('48'),
    );
    arroz = ItemInventario(
      'i2',
      Producto('p2', 'A1', 'Arroz', UnidadMedida.unidad, d('2000'), d('2800')),
      d('20'),
    );
    await items.guardarItem(tienda, huevo);
    await items.guardarItem(tienda, arroz);
  });

  Future<EntradaMercancia> entrada(
    ItemInventario item,
    String cantidad, {
    EstadoMovimiento estado = EstadoMovimiento.vigente,
    Tienda? t,
  }) async {
    final m = EntradaMercancia(
      'e${++n}',
      item,
      d(cantidad),
      fecha,
      d('400'),
      'FV-1',
    )..setEstado(estado);
    await movimientos.guardar(t ?? tienda, m);
    return m;
  }

  Future<SalidaVenta> salida(ItemInventario item, String cantidad) async {
    final m = SalidaVenta(
      's${++n}',
      item,
      -d(cantidad),
      fecha,
      Venta('v$n', const [], d('550') * d(cantidad), fecha),
      d('550'),
      d('400'),
    );
    await movimientos.guardar(tienda, m);
    return m;
  }

  ConflictoSincronizacion conflicto(TipoConflicto tipo, List<String> ids) =>
      ConflictoSincronizacion('c1', tipo, 'd', ids, fecha);

  Future<Decimal> stockGuardado(ItemInventario item) async =>
      (await items.buscarItem(tienda, item.getProducto()))!.getStockActual();

  group('admite', () {
    test('solo posible duplicado y stock negativo', () {
      for (final tipo in TipoConflicto.values) {
        expect(
          resolutor.admite(conflicto(tipo, ['x'])),
          tipo == TipoConflicto.posibleDuplicado ||
              tipo == TipoConflicto.stockNegativo,
          reason: '$tipo',
        );
      }
    });
  });

  group('posible duplicado', () {
    test(
      'anula la elegida, deja vigente la otra y recalcula el stock',
      () async {
        final e1 = await entrada(huevo, '24');
        final e2 = await entrada(
          huevo,
          '24',
          estado: EstadoMovimiento.enRevision,
        );

        await resolutor.resolver(
          tienda,
          conflicto(TipoConflicto.posibleDuplicado, [e1.getId(), e2.getId()]),
          [e2.getId()],
        );

        expect(e1.getEstado(), EstadoMovimiento.vigente);
        expect(e2.getEstado(), EstadoMovimiento.anulado);
        expect(await stockGuardado(huevo), d('24'));
      },
    );

    test('guarda el estado de cada movimiento con actualizarEstado', () async {
      final e1 = await entrada(huevo, '24');
      final e2 = await entrada(
        huevo,
        '24',
        estado: EstadoMovimiento.enRevision,
      );

      await resolutor.resolver(
        tienda,
        conflicto(TipoConflicto.posibleDuplicado, [e1.getId(), e2.getId()]),
        [e2.getId()],
      );

      expect(movimientos.estadosActualizados.map((m) => m.getId()), [
        e1.getId(),
        e2.getId(),
      ]);
    });

    test('"fueron distintas" (sin elegir nada): las dos quedan vigentes y el '
        'stock las suma', () async {
      final e1 = await entrada(huevo, '24');
      final e2 = await entrada(
        huevo,
        '24',
        estado: EstadoMovimiento.enRevision,
      );

      await resolutor.resolver(
        tienda,
        conflicto(TipoConflicto.posibleDuplicado, [e1.getId(), e2.getId()]),
        const [],
      );

      expect(e1.getEstado(), EstadoMovimiento.vigente);
      expect(e2.getEstado(), EstadoMovimiento.vigente);
      expect(await stockGuardado(huevo), d('48'));
    });

    test('un movimiento que ya estaba anulado y no se eligió sigue anulado '
        '(no se resucita lo que se anuló antes)', () async {
      final e1 = await entrada(huevo, '24');
      final e2 = await entrada(huevo, '24', estado: EstadoMovimiento.anulado);

      await resolutor.resolver(
        tienda,
        conflicto(TipoConflicto.posibleDuplicado, [e1.getId(), e2.getId()]),
        const [],
      );

      expect(e2.getEstado(), EstadoMovimiento.anulado);
      expect(await stockGuardado(huevo), d('24'));
    });

    test('elegir los dos los anula a los dos', () async {
      final e1 = await entrada(huevo, '24');
      final e2 = await entrada(huevo, '24');

      await resolutor.resolver(
        tienda,
        conflicto(TipoConflicto.posibleDuplicado, [e1.getId(), e2.getId()]),
        [e1.getId(), e2.getId()],
      );

      expect(e1.getEstado(), EstadoMovimiento.anulado);
      expect(e2.getEstado(), EstadoMovimiento.anulado);
      expect(await stockGuardado(huevo), Decimal.zero);
    });

    test('un id elegido que no es del conflicto se ignora', () async {
      final e1 = await entrada(huevo, '24');
      final e2 = await entrada(huevo, '24');
      final ajeno = await entrada(arroz, '10');

      await resolutor.resolver(
        tienda,
        conflicto(TipoConflicto.posibleDuplicado, [e1.getId(), e2.getId()]),
        [ajeno.getId()],
      );

      expect(ajeno.getEstado(), EstadoMovimiento.vigente);
      expect(movimientos.estadosActualizados.map((m) => m.getId()), [
        e1.getId(),
        e2.getId(),
      ]);
    });
  });

  group('stock negativo', () {
    test('"aceptar así" (sin elegir nada): no anula nada y el stock queda '
        'como lo dicen los movimientos, aunque sea negativo', () async {
      final e = await entrada(huevo, '4');
      final s = await salida(huevo, '10');

      await resolutor.resolver(
        tienda,
        conflicto(TipoConflicto.stockNegativo, [e.getId(), s.getId()]),
        const [],
      );

      expect(e.getEstado(), EstadoMovimiento.vigente);
      expect(s.getEstado(), EstadoMovimiento.vigente);
      expect(await stockGuardado(huevo), d('-6'));
    });

    test('anular la salida elegida corrige el stock', () async {
      final e = await entrada(huevo, '4');
      final s = await salida(huevo, '10');

      await resolutor.resolver(
        tienda,
        conflicto(TipoConflicto.stockNegativo, [e.getId(), s.getId()]),
        [s.getId()],
      );

      expect(s.getEstado(), EstadoMovimiento.anulado);
      expect(await stockGuardado(huevo), d('4'));
    });
  });

  group('recalcular el stock', () {
    test('una vez por cada ítem afectado, no por cada movimiento', () async {
      final e1 = await entrada(huevo, '24');
      final e2 = await entrada(huevo, '24');
      final a1 = await entrada(arroz, '10');
      items.guardadosEnTransaccion.clear();

      await resolutor.resolver(
        tienda,
        conflicto(TipoConflicto.posibleDuplicado, [
          e1.getId(),
          e2.getId(),
          a1.getId(),
        ]),
        const [],
      );

      // Dos ítems: dos veces guardarItem.
      expect(items.guardadosEnTransaccion, hasLength(2));
      expect(await stockGuardado(huevo), d('48'));
      expect(await stockGuardado(arroz), d('10'));
    });

    test(
      'también cuenta los movimientos del ítem que no son del conflicto',
      () async {
        await entrada(huevo, '100');
        final e1 = await entrada(huevo, '24');
        final e2 = await entrada(huevo, '24');

        await resolutor.resolver(
          tienda,
          conflicto(TipoConflicto.posibleDuplicado, [e1.getId(), e2.getId()]),
          [e2.getId()],
        );

        expect(await stockGuardado(huevo), d('124'));
      },
    );
  });

  group('errores', () {
    test('si no aparecen los movimientos: error y no cambia nada', () async {
      final e1 = await entrada(huevo, '24');

      await expectLater(
        resolutor.resolver(
          tienda,
          conflicto(TipoConflicto.posibleDuplicado, [e1.getId(), 'fantasma']),
          ['fantasma'],
        ),
        throwsA(
          isA<ExcepcionRegistrosDelConflictoNoEncontrados>().having(
            (e) => e.mensaje,
            'mensaje',
            'No se encontraron los registros de este conflicto. Actualice la '
                'pantalla',
          ),
        ),
      );
      expect(movimientos.estadosActualizados, isEmpty);
      expect(await stockGuardado(huevo), d('48'));
    });

    test('los movimientos de otra tienda no se encuentran', () async {
      final ajeno = await entrada(huevo, '24', t: otra);

      await expectLater(
        resolutor.resolver(
          tienda,
          conflicto(TipoConflicto.posibleDuplicado, [ajeno.getId()]),
          const [],
        ),
        throwsA(isA<ExcepcionRegistrosDelConflictoNoEncontrados>()),
      );
    });

    test('si guardar el estado falla, el error llega', () async {
      final e1 = await entrada(huevo, '24');
      movimientos.fallarActualizarEstado = true;

      await expectLater(
        resolutor.resolver(
          tienda,
          conflicto(TipoConflicto.posibleDuplicado, [e1.getId()]),
          const [],
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
