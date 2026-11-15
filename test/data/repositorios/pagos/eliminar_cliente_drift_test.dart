import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/pagos/cliente_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/fiado_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/venta_repositorio_drift.dart';

/// CUS-21 sobre la base local: los datos personales desaparecen de toda la
/// fila, pero los fiados, abonos y ventas pasados quedan igual (RNF-15,
/// RNF-16, DI-31).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otra = Tienda('t2', 'T002', 'La Esquina', 'Turbaco');
  Decimal d(String v) => Decimal.parse(v);
  final desde = DateTime.utc(2026, 11, 10, 5);
  final hasta = DateTime.utc(2026, 11, 11, 5);
  final dia = DateTime.utc(2026, 11, 10, 17);

  late BaseLocalDrift base;
  late ClienteRepositorioDrift clientes;
  late VentaRepositorioDrift ventas;
  late Cliente maria;

  setUp(() async {
    base = BaseLocalDrift(NativeDatabase.memory());
    clientes = ClienteRepositorioDrift(base);
    ventas = VentaRepositorioDrift(base);
    maria = Cliente('c1', 'María Pérez', '300 412 4521');
    await clientes.guardar(tienda, maria);
    // Un fiado ya saldado, con su venta de un día pasado.
    final fiado = Fiado.guardado(
      'f1',
      d('14000'),
      dia,
      maria,
      Decimal.zero,
      EstadoFiado.saldado,
    );
    await ventas.guardar(
      tienda,
      Venta(
        'v1',
        [PagoContado('p1', d('6000'), Decimal.zero), fiado],
        d('20000'),
        dia,
      ),
    );
    await FiadoRepositorioDrift(base).crear(tienda, fiado);
    await base.delete(base.colaPendientes).go();
  });
  tearDown(() => base.close());

  test('anonimiza: ninguna columna de la fila conserva el nombre ni el '
      'teléfono', () async {
    await clientes.eliminar(tienda, maria);

    final fila = await base.select(base.clientes).getSingle();
    expect(fila.id, 'c1');
    expect(fila.tiendaId, 't1');
    expect(fila.nombre, 'Cliente eliminado');
    expect(fila.nombreNormalizado, '');
    expect(fila.telefono, '');
    expect(fila.eliminadoEn, isNotNull);
    expect(fila.eliminadoEn!.isUtc, isTrue);

    // Recorre toda la fila tal como está en la base, sin mirar columnas una
    // por una: así una columna nueva con datos personales también fallaría.
    final cruda = await base.customSelect('SELECT * FROM clientes').getSingle();
    for (final valor in cruda.data.values) {
      final texto = '$valor'.toLowerCase();
      for (final dato in ['maría', 'maria', 'pérez', 'perez', '300', '4521']) {
        expect(texto, isNot(contains(dato)), reason: 'columna con "$dato"');
      }
    }
  });

  test('ya no sale en la búsqueda, ni por su nombre ni por el nuevo', () async {
    await clientes.guardar(tienda, Cliente('c2', 'Pedro', ''));
    await clientes.eliminar(tienda, maria);

    expect(await clientes.buscarPorNombre(tienda, 'maria'), isEmpty);
    expect(await clientes.buscarPorNombre(tienda, 'eliminado'), isEmpty);
    expect(await clientes.buscarPorNombre(tienda, ''), hasLength(1));
  });

  test('con otra tienda no toca al cliente ni anota nada en la cola', () async {
    await clientes.eliminar(otra, maria);

    final fila = await base.select(base.clientes).getSingle();
    expect(fila.nombre, 'María Pérez');
    expect(fila.eliminadoEn, isNull);
    expect(await base.select(base.colaPendientes).get(), isEmpty);
  });

  test(
    'se anota como ACTUALIZAR en cola_pendientes, no como ELIMINAR',
    () async {
      await clientes.eliminar(tienda, maria);

      final cola = await base.select(base.colaPendientes).get();
      expect(
        cola.map((c) => (c.tabla, c.registroId, c.operacion, c.tiendaId)),
        [('clientes', 'c1', 'ACTUALIZAR', 't1')],
      );
    },
  );

  test('los reportes de días pasados no cambian: ventas, montos, fiados y '
      'saldos quedan igual; solo el nombre se anonimiza', () async {
    Future<List<Object?>> resumen() async {
      final lista = await ventas.listarPorPeriodo(tienda, desde, hasta);
      return [
        for (final v in lista) ...[
          v.getId(),
          v.getTotal(),
          v.getFecha(),
          for (final f in v.getFormasPago()) ...[
            f.getId(),
            if (f is Fiado) ...[
              f.getMontoInicial(),
              f.getSaldoPendiente(),
              f.getEstado(),
              f.getFechaInicio(),
              f.getCliente().getId(),
            ],
          ],
        ],
      ];
    }

    final antes = await resumen();
    expect(antes, isNotEmpty);
    final filasFiado = await base.select(base.fiados).get();

    await clientes.eliminar(tienda, maria);

    expect(await resumen(), antes);
    expect(await base.select(base.fiados).get(), filasFiado);
    final lista = await ventas.listarPorPeriodo(tienda, desde, hasta);
    final fiado = lista.single.getFormasPago().whereType<Fiado>().single;
    expect(fiado.getCliente().getNombre(), 'Cliente eliminado');
    expect(fiado.getCliente().getTelefono(), '');
  });
}
