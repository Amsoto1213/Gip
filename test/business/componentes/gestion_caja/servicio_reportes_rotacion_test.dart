import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_reportes.dart';
import 'package:gip/business/entidades/gestion_caja/rotacion.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

import '../gestion_inventario/fakes_catalogo.dart';
import '../gestion_inventario/fakes_inventario.dart';
import '../pagos/fakes_pagos.dart';
import 'fakes_caja.dart';

/// clasificarRotacion (CUS-12, RF-11, DA-62, DA-72, DI-40).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otraTienda = Tienda('t2', 'T002', 'Tienda Dos', 'Turbaco');
  Decimal d(String v) => Decimal.parse(v);

  final desde = DateTime.utc(2026, 11, 5);
  final hasta = DateTime.utc(2026, 11, 12);
  final enPeriodo = DateTime.utc(2026, 11, 6);

  late InventarioRepositorioFalso inventario;
  late MovimientoRepositorioFalso movimientos;
  late ServicioReportes servicio;
  var contador = 0;

  setUp(() {
    contador = 0;
    inventario = InventarioRepositorioFalso();
    movimientos = MovimientoRepositorioFalso();
    servicio = ServicioReportes(
      VentaRepositorioFalso(),
      movimientos,
      CajaRepositorioFalso(),
      FiadoRepositorioFalso(),
      EstadoSincronizacionFalso(),
      inventario,
    );
  });

  /// Crea un producto con su ítem en el inventario de [t] (por defecto, la
  /// tienda de la prueba).
  Future<ItemInventario> producto(String nombre, {Tienda? t}) async {
    contador++;
    final item = ItemInventario(
      'i$contador',
      Producto(
        'p$contador',
        'C$contador',
        nombre,
        UnidadMedida.unidad,
        d('100'),
        d('200'),
      ),
      d('50'),
    );
    await inventario.guardarItem(t ?? tienda, item);
    return item;
  }

  Future<void> vender(
    ItemInventario item,
    String unidades, {
    DateTime? fecha,
    Tienda? t,
    EstadoMovimiento estado = EstadoMovimiento.vigente,
  }) {
    contador++;
    final cuando = fecha ?? enPeriodo;
    return movimientos.guardar(
      t ?? tienda,
      SalidaVenta(
        's$contador',
        item,
        -d(unidades),
        cuando,
        'v$contador',
        d('200'),
        d('100'),
      )..setEstado(estado),
    );
  }

  /// Rotación por nombre de producto.
  Future<Map<String, Rotacion>> clasificar([Tienda? t]) async => {
    for (final e in (await servicio.clasificarRotacion(
      t ?? tienda,
      desde,
      hasta,
    )).entries)
      e.key.getNombre(): e.value,
  };

  test('una tienda sin productos devuelve un mapa vacío', () async {
    expect(await servicio.clasificarRotacion(tienda, desde, hasta), isEmpty);
  });

  test('con 6 productos vendidos reparte 2 ALTA, 2 MEDIA y 2 BAJA', () async {
    final a = await producto('A');
    final b = await producto('B');
    final c = await producto('C');
    final e = await producto('E');
    final f = await producto('F');
    final g = await producto('G');
    await vender(a, '60');
    await vender(b, '50');
    await vender(c, '40');
    await vender(e, '30');
    await vender(f, '20');
    await vender(g, '10');

    expect(await clasificar(), {
      'A': Rotacion.alta,
      'B': Rotacion.alta,
      'C': Rotacion.media,
      'E': Rotacion.media,
      'F': Rotacion.baja,
      'G': Rotacion.baja,
    });
  });

  test('128 productos vendidos quedan en 43, 43 y 42 (mockup)', () async {
    for (var i = 1; i <= 128; i++) {
      final item = await producto('P${i.toString().padLeft(3, '0')}');
      await vender(item, '${200 - i}');
    }

    final resultado = (await clasificar()).values;

    expect(resultado.where((r) => r == Rotacion.alta), hasLength(43));
    expect(resultado.where((r) => r == Rotacion.media), hasLength(43));
    expect(resultado.where((r) => r == Rotacion.baja), hasLength(42));
  });

  test(
    'el sobrante de la división va primero a ALTA y luego a MEDIA',
    () async {
      // 7 productos: ceil(7/3)=3 ALTA, ceil(14/3)=5 -> 2 MEDIA, 2 BAJA.
      for (var i = 1; i <= 7; i++) {
        await vender(await producto('P$i'), '${10 - i}');
      }

      final resultado = (await clasificar()).values.toList();

      expect(resultado.where((r) => r == Rotacion.alta), hasLength(3));
      expect(resultado.where((r) => r == Rotacion.media), hasLength(2));
      expect(resultado.where((r) => r == Rotacion.baja), hasLength(2));
    },
  );

  test('un solo producto vendido es ALTA', () async {
    await vender(await producto('Huevo'), '5');

    expect(await clasificar(), {'Huevo': Rotacion.alta});
  });

  test('dos productos vendidos: uno ALTA y otro MEDIA', () async {
    await vender(await producto('Huevo'), '5');
    await vender(await producto('Café'), '2');

    expect(await clasificar(), {
      'Huevo': Rotacion.alta,
      'Café': Rotacion.media,
    });
  });

  test('los que no vendieron aparecen en BAJA', () async {
    await vender(await producto('Huevo'), '5');
    await producto('Velas');
    await producto('Fósforos');

    expect(await clasificar(), {
      'Huevo': Rotacion.alta,
      'Fósforos': Rotacion.baja,
      'Velas': Rotacion.baja,
    });
  });

  test(
    'sin ventas en el periodo, todos son BAJA aunque haya lugar en ALTA',
    () async {
      await producto('A');
      await producto('B');
      await producto('C');

      expect((await clasificar()).values, everyElement(Rotacion.baja));
    },
  );

  test('suma las unidades de varias salidas del mismo producto', () async {
    final huevo = await producto('Huevo');
    final cafe = await producto('Café');
    final sal = await producto('Sal');
    await vender(huevo, '3');
    await vender(huevo, '4');
    await vender(cafe, '5');
    await vender(sal, '1');

    // Huevo 7 > Café 5 > Sal 1.
    expect(await clasificar(), {
      'Huevo': Rotacion.alta,
      'Café': Rotacion.media,
      'Sal': Rotacion.baja,
    });
  });

  test(
    'usa el valor absoluto: la salida guarda la cantidad negativa',
    () async {
      final huevo = await producto('Huevo');
      final cafe = await producto('Café');
      await vender(huevo, '1.5');
      await vender(cafe, '2.5');

      expect(await clasificar(), {
        'Huevo': Rotacion.media,
        'Café': Rotacion.alta,
      });
    },
  );

  test('las salidas anuladas no cuentan', () async {
    final huevo = await producto('Huevo');
    final cafe = await producto('Café');
    await vender(huevo, '100', estado: EstadoMovimiento.anulado);
    await vender(cafe, '1');

    expect(await clasificar(), {'Café': Rotacion.alta, 'Huevo': Rotacion.baja});
  });

  test('las salidas fuera de [desde, hasta) no cuentan', () async {
    final huevo = await producto('Huevo');
    final cafe = await producto('Café');
    await vender(huevo, '50', fecha: DateTime.utc(2026, 11, 4, 23));
    await vender(huevo, '50', fecha: hasta);
    await vender(cafe, '1', fecha: desde);

    expect(await clasificar(), {'Café': Rotacion.alta, 'Huevo': Rotacion.baja});
  });

  test('los empates se ordenan por nombre', () async {
    final zeta = await producto('Zeta');
    final alfa = await producto('Alfa');
    final medio = await producto('Medio');
    await vender(zeta, '5');
    await vender(alfa, '5');
    await vender(medio, '5');

    final resultado = await servicio.clasificarRotacion(tienda, desde, hasta);

    expect(resultado.keys.map((p) => p.getNombre()), ['Alfa', 'Medio', 'Zeta']);
    expect(resultado.values, [Rotacion.alta, Rotacion.media, Rotacion.baja]);
  });

  test('el mapa viene ordenado de mayor a menor venta', () async {
    await vender(await producto('Poco'), '1');
    await vender(await producto('Mucho'), '9');
    await vender(await producto('Medio'), '5');

    final resultado = await servicio.clasificarRotacion(tienda, desde, hasta);

    expect(resultado.keys.map((p) => p.getNombre()), [
      'Mucho',
      'Medio',
      'Poco',
    ]);
  });

  test('solo cuenta los productos y las ventas de la tienda pedida', () async {
    final mio = await producto('Mío');
    final ajeno = await producto('Ajeno', t: otraTienda);
    await vender(mio, '1');
    await vender(ajeno, '99', t: otraTienda);

    expect(await clasificar(), {'Mío': Rotacion.alta});
    expect(await clasificar(otraTienda), {'Ajeno': Rotacion.alta});
  });

  test('no guarda nada: cada consulta se calcula de nuevo (DA-40)', () async {
    final huevo = await producto('Huevo');
    await producto('Café');
    await vender(huevo, '1');
    expect(await clasificar(), {'Huevo': Rotacion.alta, 'Café': Rotacion.baja});

    await vender(await producto('Sal'), '9');

    expect((await clasificar())['Sal'], Rotacion.alta);
  });
}
