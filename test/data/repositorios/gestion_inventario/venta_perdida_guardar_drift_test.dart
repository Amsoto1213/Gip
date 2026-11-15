import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_alertas.dart';
import 'package:gip/business/componentes/gestion_inventario/consumo_promedio_simple.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/alerta_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/venta_perdida_repositorio_drift.dart';

/// VentaPerdidaRepositorioDrift.guardar (CUS-13).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  late BaseLocalDrift base;
  late VentaPerdidaRepositorioDrift repo;
  late Producto coco;

  setUp(() async {
    base = BaseLocalDrift(NativeDatabase.memory());
    repo = VentaPerdidaRepositorioDrift(base);
    coco = Producto(
      'p1',
      'C1',
      'Coco',
      UnidadMedida.unidad,
      null,
      Decimal.parse('3000'),
    );
    await ProductoRepositorioDrift(base).guardar(tienda, coco);
    await base.delete(base.colaPendientes).go();
  });
  tearDown(() => base.close());

  test('guarda la venta perdida con su fecha en UTC', () async {
    final fecha = DateTime.utc(2026, 11, 15, 14, 30);
    await repo.guardar(tienda, VentaPerdida('v1', coco, fecha));

    final fila = await base.select(base.ventasPerdidas).getSingle();
    expect(fila.id, 'v1');
    expect(fila.tiendaId, 't1');
    expect(fila.productoId, 'p1');
    expect(fila.fecha.toUtc(), fecha);
  });

  test('anota INSERTAR en cola_pendientes', () async {
    await repo.guardar(
      tienda,
      VentaPerdida('v1', coco, DateTime.utc(2026, 11, 15)),
    );

    final cola = await base.select(base.colaPendientes).getSingle();
    expect(cola.tabla, 'ventas_perdidas');
    expect(cola.registroId, 'v1');
    expect(cola.operacion, 'INSERTAR');
    expect(cola.tiendaId, 't1');
  });

  test('dos registros del mismo producto no se pisan', () async {
    final fecha = DateTime.utc(2026, 11, 15, 9);
    await repo.guardar(tienda, VentaPerdida('v1', coco, fecha));
    await repo.guardar(tienda, VentaPerdida('v2', coco, fecha));

    expect(await base.select(base.ventasPerdidas).get(), hasLength(2));
    expect(await base.select(base.colaPendientes).get(), hasLength(2));
  });

  test('un id repetido no reemplaza la fila ni deja cola', () async {
    await repo.guardar(
      tienda,
      VentaPerdida('v1', coco, DateTime.utc(2026, 11, 15, 9)),
    );
    await expectLater(
      repo.guardar(
        tienda,
        VentaPerdida('v1', coco, DateTime.utc(2026, 11, 16, 9)),
      ),
      throwsA(anything),
    );

    final filas = await base.select(base.ventasPerdidas).get();
    expect(filas.single.fecha.toUtc(), DateTime.utc(2026, 11, 15, 9));
    expect(await base.select(base.colaPendientes).get(), hasLength(1));
  });

  test('aparece en la consulta de ventas perdidas de Alertas', () async {
    final servicio = ServicioAlertas(
      InventarioRepositorioDrift(base),
      MovimientoInventarioRepositorioDrift(base),
      repo,
      AlertaRepositorioDrift(base),
      ConsumoPromedioSimple(),
      7,
    );
    final registrada = await servicio.registrarVentaPerdida(tienda, coco);

    final ahora = DateTime.now();
    final lista = await servicio.obtenerVentasPerdidas(
      tienda,
      ahora.subtract(const Duration(days: 1)),
      ahora.add(const Duration(days: 1)),
    );
    expect(lista.map((v) => v.getId()), [registrada.getId()]);
    expect(lista.single.getProducto().getNombre(), 'Coco');
    expect(
      (await servicio.obtenerVentasPerdidas(
        Tienda('t2', 'T002', 'Otra', 'Turbaco'),
        ahora.subtract(const Duration(days: 1)),
        ahora.add(const Duration(days: 1)),
      )),
      isEmpty,
    );
  });
}
