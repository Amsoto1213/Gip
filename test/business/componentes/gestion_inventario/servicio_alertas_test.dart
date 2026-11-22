import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/consumo_promedio_simple.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_alertas.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

import 'fakes_alertas.dart';
import 'fakes_catalogo.dart';
import 'fakes_inventario.dart';

void main() {
  final tienda = Tienda(
    '11111111-1111-4111-8111-111111111111',
    'T001',
    'Granero El Porvenir',
    'Arjona, Bolívar',
  );
  final uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );
  Decimal d(String v) => Decimal.parse(v);

  /// Hoy, día local; el periodo es del 16 de octubre al 14 de noviembre.
  final hoy = DateTime(2026, 11, 15, 8, 30);
  final diaHoy = DateTime(2026, 11, 15);

  late InventarioRepositorioFalso items;
  late MovimientoRepositorioFalso movimientos;
  late VentaPerdidaRepositorioFalso perdidas;
  late AlertaRepositorioFalso alertas;
  late ServicioAlertas servicio;
  late Producto coco;
  late ItemInventario item;
  var n = 0;

  setUp(() async {
    items = InventarioRepositorioFalso();
    movimientos = MovimientoRepositorioFalso();
    perdidas = VentaPerdidaRepositorioFalso();
    alertas = AlertaRepositorioFalso();
    servicio = ServicioAlertas(
      items,
      movimientos,
      perdidas,
      alertas,
      ConsumoPromedioSimple(),
      7,
    );
    coco = Producto('p1', 'C1', 'Coco', UnidadMedida.unidad, null, d('3000'));
  });

  Future<void> conItem(String stock) async {
    item = ItemInventario('i1', coco, d(stock));
    await items.guardarItem(tienda, item);
  }

  void entrada(DateTime fecha, {ItemInventario? deItem}) => movimientos
      .de(tienda)
      .add(
        EntradaMercancia(
          'e${n++}',
          deItem ?? item,
          d('50'),
          fecha,
          d('2000'),
          null,
        ),
      );

  void salida(DateTime fecha, String unidades, {ItemInventario? deItem}) {
    final venta = Venta('v${n++}', const [], d('0'), fecha);
    movimientos
        .de(tienda)
        .add(
          SalidaVenta(
            's${n++}',
            deItem ?? item,
            -d(unidades),
            fecha,
            venta.getId(),
            d('3000'),
            null,
          ),
        );
  }

  /// 60 unidades en 30 días completos de historial: consumo 2 por día.
  void historialDe30DiasConConsumo2() {
    entrada(DateTime(2026, 9, 1, 9));
    salida(DateTime(2026, 10, 16, 10), '20');
    salida(DateTime(2026, 11, 1, 18), '25');
    salida(DateTime(2026, 11, 14, 21), '15');
  }

  group('generarAlertas', () {
    test(
      'con ventas: calcula consumo, cobertura y guarda la existencia',
      () async {
        await conItem('13.98');
        historialDe30DiasConConsumo2();

        final generadas = await servicio.generarAlertas(tienda, hoy);

        expect(generadas, hasLength(1));
        final alerta = generadas.single;
        expect(alerta.getId(), matches(uuidV4));
        expect(alerta.getNombreProducto(), 'Coco');
        expect(alerta.getFecha(), diaHoy);
        expect(alerta.getExistencia(), d('13.98'));
        expect(alerta.getConsumoPromedioDiario(), d('2'));
        expect(alerta.getDiasCobertura(), d('6.99'));
        expect(alerta.isProvisional(), isFalse);
      },
    );

    test('cobertura justo en el umbral (7 días) no genera alerta', () async {
      await conItem('14');
      historialDe30DiasConConsumo2();

      expect(await servicio.generarAlertas(tienda, hoy), isEmpty);
    });

    test('cobertura por debajo del umbral sí genera alerta', () async {
      await conItem('13.99');
      historialDe30DiasConConsumo2();

      final alerta = (await servicio.generarAlertas(tienda, hoy)).single;
      expect(alerta.getDiasCobertura(), d('7.00'));
    });

    test(
      'sin ventas el consumo es cero y no hay alerta aunque esté agotado',
      () async {
        await conItem('0');
        entrada(DateTime(2026, 9, 1));

        expect(await servicio.generarAlertas(tienda, hoy), isEmpty);
        expect(alertas.reemplazos, 1);
      },
    );

    test('agotado con consumo: alerta con cobertura cero', () async {
      await conItem('-1');
      historialDe30DiasConConsumo2();

      final alerta = (await servicio.generarAlertas(tienda, hoy)).single;
      expect(alerta.getDiasCobertura(), Decimal.zero);
      expect(alerta.getExistencia(), d('-1'));
    });

    test('no cuenta las ventas de hoy ni las anteriores al periodo', () async {
      await conItem('13.98');
      historialDe30DiasConConsumo2();
      salida(DateTime(2026, 10, 15, 23, 59), '100');
      salida(DateTime(2026, 11, 15, 7), '100');

      final alerta = (await servicio.generarAlertas(tienda, hoy)).single;
      expect(alerta.getConsumoPromedioDiario(), d('2'));
    });

    test(
      'con menos de 30 días de historial la alerta es provisional',
      () async {
        await conItem('3');
        entrada(DateTime(2026, 11, 5, 9)); // 10 días con datos
        salida(DateTime(2026, 11, 6), '4');
        salida(DateTime(2026, 11, 12), '6');

        final alerta = (await servicio.generarAlertas(tienda, hoy)).single;
        expect(alerta.getConsumoPromedioDiario(), d('1'));
        expect(alerta.getDiasCobertura(), d('3'));
        expect(alerta.isProvisional(), isTrue);
      },
    );

    test('con 30 días justos de historial ya no es provisional', () async {
      await conItem('3');
      entrada(DateTime(2026, 10, 16, 9));
      salida(DateTime(2026, 11, 6), '30');

      final alerta = (await servicio.generarAlertas(tienda, hoy)).single;
      expect(alerta.getConsumoPromedioDiario(), d('1'));
      expect(alerta.isProvisional(), isFalse);
    });

    test(
      'las ventas perdidas suman demanda y marcan el inicio del historial',
      () async {
        await conItem('0');
        for (var i = 0; i < 3; i++) {
          perdidas.agregar(
            tienda,
            VentaPerdida('vp$i', coco, DateTime(2026, 11, 12 + i, 10)),
          );
        }

        final alerta = (await servicio.generarAlertas(tienda, hoy)).single;
        expect(alerta.getConsumoPromedioDiario(), d('1'));
        expect(alerta.isProvisional(), isTrue);
      },
    );

    test(
      'un producto que empezó hoy no tiene días con datos ni alerta',
      () async {
        await conItem('1');
        entrada(DateTime(2026, 11, 15, 7));

        expect(await servicio.generarAlertas(tienda, hoy), isEmpty);
      },
    );

    test(
      'evalúa cada ítem y reemplaza las alertas del día una sola vez',
      () async {
        await conItem('13.98');
        historialDe30DiasConConsumo2();
        final panela = Producto(
          'p2',
          'P1',
          'Panela',
          UnidadMedida.unidad,
          null,
          d('2500'),
        );
        final itemPanela = ItemInventario('i2', panela, d('100'));
        await items.guardarItem(tienda, itemPanela);
        entrada(DateTime(2026, 9, 1), deItem: itemPanela);
        salida(DateTime(2026, 11, 1), '30', deItem: itemPanela);

        final generadas = await servicio.generarAlertas(tienda, hoy);

        expect(generadas.map((a) => a.getItemId()), ['i1']);
        expect(alertas.reemplazos, 1);
        expect(await alertas.listarPorFecha(tienda, diaHoy), hasLength(1));
      },
    );

    test('generar otra vez el mismo día no duplica las alertas', () async {
      await conItem('13.98');
      historialDe30DiasConConsumo2();

      await servicio.generarAlertas(tienda, hoy);
      await servicio.generarAlertas(tienda, hoy.add(const Duration(hours: 3)));

      expect(await servicio.obtenerAlertas(tienda, hoy), hasLength(1));
      expect(alertas.reemplazos, 2);
    });
  });

  group('consultas', () {
    test('obtenerAlertas lee las del día, sin calcular', () async {
      await conItem('13.98');
      historialDe30DiasConConsumo2();
      await servicio.generarAlertas(tienda, hoy);

      expect(await servicio.obtenerAlertas(tienda, hoy), hasLength(1));
      expect(
        await servicio.obtenerAlertas(tienda, DateTime(2026, 11, 16)),
        isEmpty,
      );
    });

    test('obtenerVentasPerdidas trae las de la tienda en el periodo', () async {
      perdidas.agregar(tienda, VentaPerdida('a', coco, DateTime(2026, 11, 3)));
      perdidas.agregar(tienda, VentaPerdida('b', coco, DateTime(2026, 10, 1)));

      final encontradas = await servicio.obtenerVentasPerdidas(
        tienda,
        DateTime(2026, 10, 16),
        diaHoy,
      );
      expect(encontradas.map((v) => v.getId()), ['a']);
    });
  });

  group('registrarVentaPerdida (CUS-13)', () {
    test(
      'guarda la venta perdida con id v4, producto y fecha de ahora',
      () async {
        final antes = DateTime.now().toUtc();
        final venta = await servicio.registrarVentaPerdida(tienda, coco);
        final despues = DateTime.now().toUtc();

        expect(uuidV4.hasMatch(venta.getId()), isTrue);
        expect(venta.getProductoId(), coco.getId());
        expect(venta.getFecha().isUtc, isTrue);
        expect(venta.getFecha().isBefore(antes), isFalse);
        expect(venta.getFecha().isAfter(despues), isFalse);
        expect(perdidas.datos[tienda.getId()], [venta]);
      },
    );

    test('dos registros del mismo producto no se pisan', () async {
      final a = await servicio.registrarVentaPerdida(tienda, coco);
      final b = await servicio.registrarVentaPerdida(tienda, coco);

      expect(a.getId(), isNot(b.getId()));
      expect(perdidas.datos[tienda.getId()], hasLength(2));
    });

    test('aparece en obtenerVentasPerdidas', () async {
      final venta = await servicio.registrarVentaPerdida(tienda, coco);
      final ahora = DateTime.now();

      final encontradas = await servicio.obtenerVentasPerdidas(
        tienda,
        ahora.subtract(const Duration(days: 1)),
        ahora.add(const Duration(days: 1)),
      );
      expect(encontradas, [venta]);
    });
  });
}
