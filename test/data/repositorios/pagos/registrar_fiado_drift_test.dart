import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/pagos/procesador_fiado.dart';
import 'package:gip/business/componentes/pagos/procesador_nequi.dart';
import 'package:gip/business/componentes/pagos/procesador_pago_contado.dart';
import 'package:gip/business/componentes/pagos/servicio_clientes.dart';
import 'package:gip/business/componentes/pagos/servicio_fiados.dart';
import 'package:gip/business/componentes/pagos/servicio_ventas.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/interfaces/pagos/i_fiado_repositorio.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/cliente_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/fiado_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/venta_repositorio_drift.dart';

/// Inserta con el repositorio real y luego falla, para probar que el rollback
/// también deshace el fiado ya escrito.
class FiadoQueFallaDespues implements IFiadoRepositorio {
  FiadoQueFallaDespues(this._real);

  final IFiadoRepositorio _real;

  @override
  Future<void> crear(Tienda tienda, Fiado fiado) async {
    await _real.crear(tienda, fiado);
    throw StateError('falla del disco');
  }

  @override
  Future<void> registrarAbono(Tienda tienda, Fiado fiado, Abono abono) =>
      _real.registrarAbono(tienda, fiado, abono);

  @override
  Future<List<Abono>> listarAbonos(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) => _real.listarAbonos(tienda, desde, hasta);
}

/// CUS-07 de punta a punta sobre la base local: el fiado se guarda con la
/// venta, en la misma transacción.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otra = Tienda('t2', 'T002', 'Otra tienda', 'Turbaco');
  Decimal d(String v) => Decimal.parse(v);

  late BaseLocalDrift base;
  late UnidadTrabajoDrift unidad;
  late InventarioRepositorioDrift items;
  late ServicioInventario inventario;
  late ClienteRepositorioDrift clientes;
  late ServicioClientes servicioClientes;
  late Producto arroz;

  ({ServicioVentas ventas, ServicioFiados fiados}) servicios({
    IFiadoRepositorio? fiados,
  }) {
    final servicioFiados = ServicioFiados(
      fiados ?? FiadoRepositorioDrift(base),
    );
    return (
      ventas: ServicioVentas(
        inventario,
        [
          ProcesadorPagoContado(ServicioCaja(CajaRepositorioDrift(base))),
          ProcesadorNequi(),
          ProcesadorFiado(servicioFiados),
        ],
        VentaRepositorioDrift(base),
        unidad,
      ),
      fiados: servicioFiados,
    );
  }

  setUp(() async {
    base = BaseLocalDrift(NativeDatabase.memory());
    unidad = UnidadTrabajoDrift(base);
    items = InventarioRepositorioDrift(base);
    inventario = ServicioInventario(
      items,
      MovimientoInventarioRepositorioDrift(base),
      d('5'),
      unidad,
    );
    clientes = ClienteRepositorioDrift(base);
    servicioClientes = ServicioClientes(clientes);
    arroz = Producto(
      'p-arroz',
      'ARR',
      'Arroz 500 g',
      UnidadMedida.unidad,
      d('2000'),
      d('2800'),
    );
    await ProductoRepositorioDrift(base).guardar(tienda, arroz);
    await items.guardarItem(tienda, ItemInventario('i-arroz', arroz, d('10')));
    await base.delete(base.colaPendientes).go();
  });
  tearDown(() => base.close());

  Future<Decimal> stock() async =>
      (await items.buscarItem(tienda, arroz))!.getStockActual();

  Future<int> contar(String tabla) async =>
      (await base.customSelect('SELECT COUNT(*) AS n FROM $tabla').getSingle())
          .read<int>('n');

  Future<List<LineaVenta>> lineas(ServicioVentas ventas, String n) async {
    final ls = <LineaVenta>[];
    await ventas.agregarLinea(tienda, ls, arroz, d(n));
    return ls;
  }

  group('clientes', () {
    test(
      'registrar cliente nuevo: guarda la fila y la anota en la cola',
      () async {
        final cliente = await servicioClientes.registrarCliente(
          tienda,
          'María Pérez',
          '',
        );

        final fila = await base.select(base.clientes).getSingle();
        expect(fila.id, cliente.getId());
        expect(fila.tiendaId, 't1');
        expect(fila.nombreNormalizado, 'maria perez');
        expect(fila.telefono, '');
        expect(fila.actualizadoEn.isUtc, isTrue);
        final cola = await base.select(base.colaPendientes).getSingle();
        expect(
          (cola.tabla, cola.registroId, cola.operacion),
          ('clientes', cliente.getId(), 'INSERTAR'),
        );
      },
    );

    test(
      'buscar por nombre sin tildes ni mayúsculas, solo de la tienda',
      () async {
        await clientes.guardar(tienda, Cliente('c1', 'María Pérez', '300'));
        await clientes.guardar(tienda, Cliente('c2', 'Pedro Gómez', ''));
        await clientes.guardar(otra, Cliente('c3', 'María Otra', ''));

        final encontrados = await servicioClientes.buscarClientes(
          tienda,
          'MARIA',
        );
        expect(encontrados.map((c) => c.getId()), ['c1']);
        expect(encontrados.single.getTelefono(), '300');
        expect(await servicioClientes.buscarClientes(tienda, '%'), isEmpty);
      },
    );
  });

  test('venta con efectivo + fiado: guarda venta, forma FIADO, fiado, salida '
      'y solo el efectivo en caja, todo con su cola', () async {
    final s = servicios();
    final maria = await servicioClientes.registrarCliente(
      tienda,
      'María Pérez',
      '3004124521',
    );
    await base.delete(base.colaPendientes).go();
    final ls = await lineas(s.ventas, '5'); // 14.000
    final contado = s.ventas.crearPagoContado(d('5000'), d('5000'));
    final fiado = s.fiados.crearFiado(maria, d('9000'));

    final venta = await s.ventas.confirmar(tienda, ls, [contado, fiado]);

    final formaFiado = await (base.select(
      base.formasPago,
    )..where((f) => f.tipo.equals('FIADO'))).getSingle();
    expect(formaFiado.id, fiado.getId());
    expect(formaFiado.ventaId, venta.getId());
    expect(formaFiado.monto, d('9000'));

    final filaFiado = await base.select(base.fiados).getSingle();
    expect(filaFiado.id, fiado.getId());
    expect(filaFiado.tiendaId, 't1');
    expect(filaFiado.clienteId, maria.getId());
    expect(filaFiado.montoInicial, d('9000'));
    expect(filaFiado.saldoPendiente, d('9000'));
    expect(filaFiado.estado, 'PENDIENTE');

    expect(
      (await base.select(base.movimientosCaja).getSingle()).valor,
      d('5000'),
    );
    expect(await stock(), d('5'));

    final cola = await base.select(base.colaPendientes).get();
    expect(cola.map((c) => c.tabla).toList()..sort(), [
      'cajas',
      'fiados',
      'formas_pago',
      'formas_pago',
      'items_inventario',
      'movimientos_caja',
      'movimientos_inventario',
      'ventas',
    ]);

    // Al buscar al cliente, trae su fiado pendiente con el saldo.
    final encontrada = (await servicioClientes.buscarClientes(
      tienda,
      'maria',
    )).single;
    final pendiente = encontrada.obtenerFiadosPendientes().single;
    expect(pendiente.getId(), fiado.getId());
    expect(pendiente.getEstado(), EstadoFiado.pendiente);
    expect(encontrada.calcularSaldoPendiente(), d('9000'));
  });

  test('fiado solo y fiado + Nequi: no mueven la caja', () async {
    final s = servicios();
    final ana = await servicioClientes.registrarCliente(tienda, 'Ana', '');

    await s.ventas.confirmar(tienda, await lineas(s.ventas, '1'), [
      s.fiados.crearFiado(ana, d('2800')),
    ]);
    await s.ventas.confirmar(tienda, await lineas(s.ventas, '2'), [
      s.ventas.crearPagoNequi(d('600'), null),
      s.fiados.crearFiado(ana, d('5000')),
    ]);

    expect(await contar('fiados'), 2);
    expect(await contar('cajas'), 0);
    expect(await contar('movimientos_caja'), 0);
    final buscada = (await servicioClientes.buscarClientes(
      tienda,
      'ana',
    )).single;
    expect(buscada.calcularSaldoPendiente(), d('7800'));
  });

  test('si falla el guardado del fiado no queda ni venta ni fiado (el cliente '
      'registrado antes sí)', () async {
    final s = servicios(
      fiados: FiadoQueFallaDespues(FiadoRepositorioDrift(base)),
    );
    final ana = await servicioClientes.registrarCliente(tienda, 'Ana', '');
    final colaAntes = await contar('cola_pendientes');
    final ls = await lineas(s.ventas, '2'); // 5.600

    await expectLater(
      s.ventas.confirmar(tienda, ls, [
        s.ventas.crearPagoContado(d('600'), d('1000')),
        s.fiados.crearFiado(ana, d('5000')),
      ]),
      throwsA(isA<StateError>()),
    );

    for (final t in [
      'ventas',
      'formas_pago',
      'fiados',
      'movimientos_inventario',
      'cajas',
      'movimientos_caja',
    ]) {
      expect(await contar(t), 0, reason: t);
    }
    expect(await contar('cola_pendientes'), colaAntes);
    expect(await contar('clientes'), 1);
    expect(await stock(), d('10'));
  });
}
