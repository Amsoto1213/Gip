import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/ajuste_conteo.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

import 'fakes_catalogo.dart';
import 'fakes_inventario.dart';

/// recalcularStock (CUS-22, ERS 3.2.1 c, DA-48, DI-45): el stock sale de los
/// movimientos vigentes, no de un número que se sincronice.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);
  final fecha = DateTime.utc(2026, 11, 15, 15);

  late InventarioRepositorioFalso items;
  late MovimientoRepositorioFalso movimientos;
  late ServicioInventario servicio;
  late ItemInventario huevo;
  var n = 0;

  setUp(() async {
    n = 0;
    items = InventarioRepositorioFalso();
    movimientos = MovimientoRepositorioFalso();
    final productos = ProductoRepositorioFalso();
    final unidad = UnidadTrabajoFalsa([items, movimientos, productos]);
    servicio = ServicioInventario(
      items,
      movimientos,
      d('5'),
      unidad,
      productos,
    );
    huevo = ItemInventario(
      'i1',
      Producto('p1', 'H1', 'Huevo AA', UnidadMedida.unidad, d('400'), d('550')),
      // Un número viejo, de antes de unir los registros de los equipos.
      d('999'),
    );
    await items.guardarItem(tienda, huevo);
  });

  Future<MovimientoInventario> entrada(String cantidad) async {
    final m = EntradaMercancia(
      'm${++n}',
      huevo,
      d(cantidad),
      fecha,
      d('400'),
      null,
    );
    await movimientos.guardar(tienda, m);
    return m;
  }

  Future<MovimientoInventario> salida(String cantidad) async {
    final m = SalidaVenta(
      'm${++n}',
      huevo,
      -d(cantidad),
      fecha,
      Venta('v$n', const [], d('550') * d(cantidad), fecha),
      d('550'),
      d('400'),
    );
    await movimientos.guardar(tienda, m);
    return m;
  }

  Future<ItemInventario> guardado() async =>
      (await items.buscarItem(tienda, huevo.getProducto()))!;

  test('suma las entradas y resta las salidas', () async {
    await entrada('24');
    await entrada('12');
    await salida('10');

    final stock = await servicio.recalcularStock(tienda, huevo);

    expect(stock, d('26'));
    expect(huevo.getStockActual(), d('26'));
  });

  test('guarda el stock recalculado en el ítem', () async {
    await entrada('24');

    await servicio.recalcularStock(tienda, huevo);

    expect((await guardado()).getStockActual(), d('24'));
  });

  test('si el stock no cambió no escribe el ítem: cada escritura entraría a '
      'la cola de sincronización', () async {
    await entrada('24');
    await servicio.recalcularStock(tienda, huevo);
    items.guardadosEnTransaccion.clear();

    await servicio.recalcularStock(tienda, huevo);

    expect(items.guardadosEnTransaccion, isEmpty);
    expect((await guardado()).getStockActual(), d('24'));
  });

  test(
    'no cuenta los movimientos anulados ni los que están en revisión',
    () async {
      await entrada('24');
      (await entrada('24')).setEstado(EstadoMovimiento.anulado);
      (await entrada('24')).setEstado(EstadoMovimiento.enRevision);

      expect(await servicio.recalcularStock(tienda, huevo), d('24'));
    },
  );

  test(
    'cuenta las mermas (negativas) y los ajustes de conteo (con signo)',
    () async {
      await entrada('30');
      await movimientos.guardar(
        tienda,
        Merma('m${++n}', huevo, -d('4'), fecha, MotivoMerma.vencido),
      );
      await movimientos.guardar(
        tienda,
        AjusteConteo('m${++n}', huevo, -d('2'), fecha, d('24')),
      );

      expect(await servicio.recalcularStock(tienda, huevo), d('24'));
    },
  );

  test('puede quedar negativo: eso es lo que revisa el propietario', () async {
    await entrada('4');
    await salida('10');

    expect(await servicio.recalcularStock(tienda, huevo), d('-6'));
    expect((await guardado()).getStockActual(), d('-6'));
  });

  test('un ítem sin movimientos queda en cero', () async {
    expect(await servicio.recalcularStock(tienda, huevo), Decimal.zero);
  });

  test('cuenta todo el historial, también lo muy antiguo', () async {
    await movimientos.guardar(
      tienda,
      EntradaMercancia(
        'm${++n}',
        huevo,
        d('10'),
        DateTime.utc(2020, 1, 1),
        d('400'),
        null,
      ),
    );
    await entrada('5');

    expect(await servicio.recalcularStock(tienda, huevo), d('15'));
  });

  test('al anular un movimiento y recalcular, el stock lo descuenta', () async {
    await entrada('24');
    final repetida = await entrada('24');
    await servicio.recalcularStock(tienda, huevo);
    expect(huevo.getStockActual(), d('48'));

    repetida.setEstado(EstadoMovimiento.anulado);
    await servicio.recalcularStock(tienda, huevo);

    expect(huevo.getStockActual(), d('24'));
  });

  test('recalcular dos veces da lo mismo', () async {
    await entrada('24');
    await servicio.recalcularStock(tienda, huevo);

    expect(await servicio.recalcularStock(tienda, huevo), d('24'));
  });
}
