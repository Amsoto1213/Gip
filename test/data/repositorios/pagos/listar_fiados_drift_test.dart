import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/pagos/cliente_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/fiado_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/venta_repositorio_drift.dart';

/// IFiadoRepositorio.listar sobre la base local (CUS-16, DI-41): todos los
/// fiados de la tienda con su cliente y sus abonos.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otra = Tienda('t2', 'T002', 'La Esquina', 'Turbaco');
  Decimal d(String v) => Decimal.parse(v);

  late BaseLocalDrift base;
  late ClienteRepositorioDrift clientes;
  late VentaRepositorioDrift ventas;
  late FiadoRepositorioDrift fiados;

  setUp(() {
    base = BaseLocalDrift(NativeDatabase.memory());
    clientes = ClienteRepositorioDrift(base);
    ventas = VentaRepositorioDrift(base);
    fiados = FiadoRepositorioDrift(base);
  });
  tearDown(() => base.close());

  /// Guarda la venta fiada y el fiado, como lo hace CUS-07.
  Future<Fiado> fiar(
    Tienda t,
    String id,
    Cliente cliente,
    String monto,
    DateTime fecha,
  ) async {
    final fiado = Fiado(id, d(monto), fecha, cliente);
    await ventas.guardar(t, Venta('v$id', [fiado], d(monto), fecha));
    await fiados.crear(t, fiado);
    return fiado;
  }

  Future<void> abonar(
    Tienda t,
    Fiado fiado,
    String id,
    String monto,
    DateTime fecha, {
    MedioPago medio = MedioPago.efectivo,
  }) async {
    final abono = fiado.registrarAbono(Abono(id, d(monto), fecha, medio, null));
    await fiados.registrarAbono(t, fiado, abono);
  }

  test('sin fiados devuelve una lista vacía', () async {
    expect(await fiados.listar(tienda), isEmpty);
  });

  test('trae todos los estados, del más reciente al más antiguo', () async {
    final maria = Cliente('c1', 'María Pérez', '300 412 4521');
    await clientes.guardar(tienda, maria);
    await fiar(tienda, 'f1', maria, '10000', DateTime.utc(2026, 10, 1));
    final saldado = await fiar(
      tienda,
      'f2',
      maria,
      '5000',
      DateTime.utc(2026, 10, 10),
    );
    await abonar(tienda, saldado, 'a1', '5000', DateTime.utc(2026, 10, 12));
    final anulado = await fiar(
      tienda,
      'f3',
      maria,
      '2000',
      DateTime.utc(2026, 10, 20),
    );
    anulado.anular();
    await fiados.actualizarSaldo(tienda, anulado);

    final lista = await fiados.listar(tienda);

    expect(lista.map((f) => f.getId()), ['f3', 'f2', 'f1']);
    expect(lista.map((f) => f.getEstado()), [
      EstadoFiado.anulado,
      EstadoFiado.saldado,
      EstadoFiado.pendiente,
    ]);
    expect(lista[2].getSaldoPendiente(), d('10000'));
    expect(lista[1].getSaldoPendiente(), Decimal.zero);
    expect(lista[1].getMontoInicial(), d('5000'));
  });

  test('cada fiado trae su cliente y sus abonos del más antiguo al más '
      'reciente, con el medio y los anulados', () async {
    final maria = Cliente('c1', 'María Pérez', '300 412 4521');
    final pedro = Cliente('c2', 'Pedro Gómez', '');
    await clientes.guardar(tienda, maria);
    await clientes.guardar(tienda, pedro);
    final deMaria = await fiar(
      tienda,
      'f1',
      maria,
      '20000',
      DateTime.utc(2026, 10, 1),
    );
    await fiar(tienda, 'f2', pedro, '3000', DateTime.utc(2026, 10, 2));
    await abonar(
      tienda,
      deMaria,
      'a2',
      '4000',
      DateTime.utc(2026, 10, 9),
      medio: MedioPago.nequi,
    );
    await abonar(tienda, deMaria, 'a1', '1000', DateTime.utc(2026, 10, 5));

    final lista = await fiados.listar(tienda);

    final f1 = lista.firstWhere((f) => f.getId() == 'f1');
    expect(f1.getCliente().getNombre(), 'María Pérez');
    expect(f1.getCliente().getTelefono(), '300 412 4521');
    expect(f1.getAbonos().map((a) => a.getId()), ['a1', 'a2']);
    expect(f1.getAbonos().map((a) => a.getMonto()), [d('1000'), d('4000')]);
    expect(f1.getAbonos().last.getMedio(), MedioPago.nequi);
    expect(f1.getSaldoPendiente(), d('15000'));
    final f2 = lista.firstWhere((f) => f.getId() == 'f2');
    expect(f2.getCliente().getNombre(), 'Pedro Gómez');
    expect(f2.getAbonos(), isEmpty);
  });

  test('el cliente eliminado sale anonimizado, no desaparece', () async {
    final maria = Cliente('c1', 'María Pérez', '300 412 4521');
    await clientes.guardar(tienda, maria);
    await fiar(tienda, 'f1', maria, '5000', DateTime.utc(2026, 10, 1));
    await clientes.eliminar(tienda, maria);

    final lista = await fiados.listar(tienda);

    expect(lista, hasLength(1));
    expect(lista.single.getCliente().getNombre(), 'Cliente eliminado');
    expect(lista.single.getCliente().getTelefono(), '');
  });

  test('solo trae los fiados de la tienda pedida', () async {
    final maria = Cliente('c1', 'María Pérez', '');
    final luis = Cliente('c2', 'Luis Díaz', '');
    await clientes.guardar(tienda, maria);
    await clientes.guardar(otra, luis);
    await fiar(tienda, 'f1', maria, '5000', DateTime.utc(2026, 10, 1));
    final ajeno = await fiar(
      otra,
      'f2',
      luis,
      '7000',
      DateTime.utc(2026, 10, 2),
    );
    await abonar(otra, ajeno, 'a1', '1000', DateTime.utc(2026, 10, 3));

    expect((await fiados.listar(tienda)).map((f) => f.getId()), ['f1']);
    final deOtra = await fiados.listar(otra);
    expect(deOtra.map((f) => f.getId()), ['f2']);
    expect(deOtra.single.getAbonos(), hasLength(1));
    expect((await fiados.listar(tienda)).single.getAbonos(), isEmpty);
  });
}
