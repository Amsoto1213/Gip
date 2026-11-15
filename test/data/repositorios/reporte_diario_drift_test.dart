import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/cliente_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/fiado_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/venta_repositorio_drift.dart';
import 'package:gip/data/service_agents/estado_sincronizacion_drift.dart';

/// Consultas de CUS-10 sobre la base local: por periodo `[desde, hasta)`, solo
/// de la tienda pedida (DI-29).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otraTienda = Tienda('t2', 'T002', 'La Esquina', 'Turbaco');
  Decimal d(String v) => Decimal.parse(v);
  final desde = DateTime.utc(2026, 11, 14, 5);
  final hasta = DateTime.utc(2026, 11, 15, 5);
  final dentro = DateTime.utc(2026, 11, 14, 17);
  final ayer = DateTime.utc(2026, 11, 13, 17);

  late BaseLocalDrift base;

  setUp(() => base = BaseLocalDrift(NativeDatabase.memory()));
  tearDown(() => base.close());

  PagoContado contado(String id, String monto, [String cambio = '0']) =>
      PagoContado(id, d(monto), d(cambio));

  test('listarPorPeriodo trae las ventas del periodo con sus formas', () async {
    final ventas = VentaRepositorioDrift(base);
    final ana = Cliente('c1', 'Ana', '');
    await ClienteRepositorioDrift(base).guardar(tienda, ana);
    final fiado = Fiado('f1', d('3000'), dentro, ana);
    await ventas.guardar(
      tienda,
      Venta(
        'v1',
        [
          contado('p1', '10000', '2000'),
          PagoNequi('p2', d('5000'), null),
          fiado,
        ],
        d('16000'),
        dentro,
      ),
    );
    await FiadoRepositorioDrift(base).crear(tienda, fiado);
    await ventas.guardar(
      tienda,
      Venta('v2', [contado('p3', '100')], d('100'), ayer),
    );
    await ventas.guardar(
      tienda,
      Venta('v3', [contado('p4', '100')], d('100'), hasta),
    );
    await ventas.guardar(
      otraTienda,
      Venta('v4', [contado('p5', '100')], d('100'), dentro),
    );

    final lista = await ventas.listarPorPeriodo(tienda, desde, hasta);

    expect(lista.map((v) => v.getId()), ['v1']);
    final formas = lista.single.getFormasPago();
    expect(formas.map((f) => f.calcularMontoCubierto()), [
      d('8000'),
      d('5000'),
      d('3000'),
    ]);
    expect(formas.whereType<Fiado>().single.getCliente().getNombre(), 'Ana');
  });

  test('listarAbonos respeta periodo y tienda, y trae los anulados', () async {
    final ventas = VentaRepositorioDrift(base);
    final fiados = FiadoRepositorioDrift(base);
    final ana = Cliente('c1', 'Ana', '');
    await ClienteRepositorioDrift(base).guardar(tienda, ana);
    final fiado = Fiado('f1', d('9000'), dentro, ana);
    await ventas.guardar(tienda, Venta('v1', [fiado], d('9000'), dentro));
    await fiados.crear(tienda, fiado);
    for (final abono in [
      Abono('a1', d('1000'), dentro, MedioPago.nequi, 'R1'),
      Abono('a2', d('500'), ayer, MedioPago.efectivo, null),
      Abono('a3', d('200'), dentro, MedioPago.efectivo, null, anulado: true),
    ]) {
      await fiados.registrarAbono(tienda, fiado, fiado.registrarAbono(abono));
    }

    final lista = await fiados.listarAbonos(tienda, desde, hasta);

    expect(lista.map((a) => a.getId()), ['a1', 'a3']);
    expect(lista.map((a) => a.isAnulado()), [false, true]);
    expect(lista.first.getMedio(), MedioPago.nequi);
    expect(await fiados.listarAbonos(otraTienda, desde, hasta), isEmpty);
  });

  test('listarMovimientos respeta periodo y tienda', () async {
    final cajas = CajaRepositorioDrift(base);
    MovimientoCaja mov(String id, DateTime fecha, TipoMovimientoCaja tipo) =>
        MovimientoCaja(
          id,
          d('1000'),
          id,
          ClasificacionMovimiento.negocio,
          tipo,
          fecha,
        );
    final caja = Caja('t1_2026-11-14', DateTime(2026, 11, 14));
    await cajas.crear(tienda, caja);
    await cajas.registrarMovimiento(
      tienda,
      caja,
      mov('m1', dentro, TipoMovimientoCaja.ingreso),
    );
    await cajas.registrarMovimiento(
      tienda,
      caja,
      mov('m2', hasta, TipoMovimientoCaja.egreso),
    );
    final otra = Caja('t2_2026-11-14', DateTime(2026, 11, 14));
    await cajas.crear(otraTienda, otra);
    await cajas.registrarMovimiento(
      otraTienda,
      otra,
      mov('m3', dentro, TipoMovimientoCaja.ingreso),
    );

    final lista = await cajas.listarMovimientos(tienda, desde, hasta);

    expect(lista.map((m) => m.getId()), ['m1']);
    expect(lista.single.esIngreso(), isTrue);
    expect(lista.single.esDelNegocio(), isTrue);
  });

  test('listarEntradasPorTienda trae solo entradas del periodo', () async {
    final producto = Producto(
      'p1',
      'A1',
      'Aceite',
      UnidadMedida.unidad,
      null,
      d('11000'),
    );
    await ProductoRepositorioDrift(base).guardar(tienda, producto);
    final item = ItemInventario('i1', producto, d('0'));
    await InventarioRepositorioDrift(base).guardarItem(tienda, item);
    final movimientos = MovimientoInventarioRepositorioDrift(base);
    await movimientos.guardar(
      tienda,
      EntradaMercancia('e1', item, d('24'), dentro, d('8600'), null),
    );
    await movimientos.guardar(
      tienda,
      EntradaMercancia('e2', item, d('1'), ayer, d('8600'), null),
    );

    final lista = await movimientos.listarEntradasPorTienda(
      tienda,
      desde,
      hasta,
    );

    expect(lista.map((e) => e.getId()), ['e1']);
    expect(lista.single.calcularCostoTotal(), d('206400'));
    expect(lista.single.getItem().getProducto().getNombre(), 'Aceite');
    expect(
      await movimientos.listarEntradasPorTienda(otraTienda, desde, hasta),
      isEmpty,
    );
  });

  test(
    'hayPendientes es verdadero si la cola de la tienda tiene filas',
    () async {
      final estado = EstadoSincronizacionDrift(base);
      expect(await estado.hayPendientes(tienda), isFalse);

      await ClienteRepositorioDrift(base)
          .guardar(tienda, Cliente('c1', 'Ana', ''));

      expect(await estado.hayPendientes(tienda), isTrue);
      expect(await estado.hayPendientes(otraTienda), isFalse);
    },
  );
}
