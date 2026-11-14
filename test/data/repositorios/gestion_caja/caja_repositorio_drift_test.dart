import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otraTienda = Tienda('t2', 'T002', 'La Esquina', 'Turbaco');
  Decimal d(String v) => Decimal.parse(v);
  final dia = DateTime(2026, 11, 14);

  late BaseLocalDrift base;
  late CajaRepositorioDrift cajas;

  setUp(() {
    base = BaseLocalDrift(NativeDatabase.memory());
    cajas = CajaRepositorioDrift(base);
  });
  tearDown(() => base.close());

  Caja nueva(Tienda t) => Caja('${t.getId()}_2026-11-14', dia);

  MovimientoCaja mov(String id, String valor, DateTime fecha) => MovimientoCaja(
    id,
    d(valor),
    'Venta $id',
    ClasificacionMovimiento.negocio,
    TipoMovimientoCaja.ingreso,
    fecha,
  );

  Future<List<String>> cola() async =>
      (await base.select(base.colaPendientes).get())
          .map((e) => '${e.tabla}:${e.registroId}:${e.tiendaId}')
          .toList();

  test('sin caja del día devuelve null', () async {
    expect(await cajas.buscarPorFecha(tienda, dia), isNull);
  });

  test(
    'crear guarda la caja con la fecha como día y la anota en la cola',
    () async {
      final caja = nueva(tienda);
      await cajas.crear(tienda, caja);

      final fila = await base.select(base.cajas).getSingle();
      expect(fila.id, 't1_2026-11-14');
      expect(fila.fecha, '2026-11-14');
      expect(fila.tiendaId, 't1');
      expect(await cola(), ['cajas:t1_2026-11-14:t1']);
    },
  );

  test('crear la misma caja dos veces no falla ni la repite (DA-62)', () async {
    await cajas.crear(tienda, nueva(tienda));
    await cajas.crear(tienda, nueva(tienda));

    expect(await base.select(base.cajas).get(), hasLength(1));
    expect(await cola(), hasLength(1));
  });

  test('buscarPorFecha trae la caja con sus movimientos en orden', () async {
    final caja = nueva(tienda);
    await cajas.crear(tienda, caja);
    await cajas.registrarMovimiento(
      tienda,
      caja,
      mov('m2', '12000', DateTime.utc(2026, 11, 14, 20)),
    );
    await cajas.registrarMovimiento(
      tienda,
      caja,
      mov('m1', '32000', DateTime.utc(2026, 11, 14, 15)),
    );

    final leida = (await cajas.buscarPorFecha(tienda, dia))!;
    expect(leida.getId(), caja.getId());
    expect(leida.getFecha(), dia);
    expect(leida.getMovimientos().map((m) => m.getId()), ['m1', 'm2']);
    final m1 = leida.getMovimientos().first;
    expect(m1.getValor(), d('32000'));
    expect(m1.getTipo(), TipoMovimientoCaja.ingreso);
    expect(m1.getClasificacion(), ClasificacionMovimiento.negocio);
    expect(m1.getFecha(), DateTime.utc(2026, 11, 14, 15));
    expect(leida.calcularSaldoEsperado(), d('44000'));
    expect(
      await cola(),
      containsAll(['movimientos_caja:m1:t1', 'movimientos_caja:m2:t1']),
    );
  });

  test('cada tienda ve solo su caja', () async {
    await cajas.crear(tienda, nueva(tienda));
    expect(await cajas.buscarPorFecha(otraTienda, dia), isNull);
  });

  test(
    'registrarMovimiento guarda tipo y clasificación como en Supabase',
    () async {
      final caja = nueva(tienda);
      await cajas.crear(tienda, caja);
      await cajas.registrarMovimiento(
        tienda,
        caja,
        MovimientoCaja(
          'm9',
          d('5000'),
          'Anulacion venta v1',
          ClasificacionMovimiento.anulacion,
          TipoMovimientoCaja.egreso,
          DateTime.utc(2026, 11, 14),
        ),
      );
      final fila = await base.select(base.movimientosCaja).getSingle();
      expect(fila.tipo, 'EGRESO');
      expect(fila.clasificacion, 'ANULACION');
      expect(fila.cajaId, caja.getId());
    },
  );
}
