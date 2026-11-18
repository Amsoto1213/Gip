import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/pagos/procesador_fiado.dart';
import 'package:gip/business/componentes/pagos/procesador_nequi.dart';
import 'package:gip/business/componentes/pagos/procesador_pago_contado.dart';
import 'package:gip/business/componentes/pagos/servicio_abonos.dart';
import 'package:gip/business/componentes/pagos/servicio_clientes.dart';
import 'package:gip/business/componentes/pagos/servicio_fiados.dart';
import 'package:gip/business/componentes/pagos/servicio_ventas.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/business/interfaces/gestion_caja/i_caja_repositorio.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/cliente_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/fiado_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/venta_repositorio_drift.dart';

/// Guarda el movimiento con el repositorio real y luego falla, para probar que
/// el rollback también deshace el abono y el saldo ya escritos.
class CajaQueFallaDespues implements ICajaRepositorio {
  CajaQueFallaDespues(this._real);

  final ICajaRepositorio _real;

  @override
  Future<Caja?> buscarPorFecha(Tienda tienda, DateTime fecha) =>
      _real.buscarPorFecha(tienda, fecha);

  @override
  Future<void> crear(Tienda tienda, Caja caja) => _real.crear(tienda, caja);

  @override
  Future<void> cerrar(Tienda tienda, Caja caja) => _real.cerrar(tienda, caja);

  @override
  Future<void> registrarMovimiento(
    Tienda tienda,
    Caja caja,
    MovimientoCaja movimiento,
  ) async {
    await _real.registrarMovimiento(tienda, caja, movimiento);
    throw StateError('falla del disco');
  }

  @override
  Future<List<MovimientoCaja>> listarMovimientos(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) => _real.listarMovimientos(tienda, desde, hasta);
}

/// CUS-08 de punta a punta sobre la base local: el abono, el nuevo saldo del
/// fiado y el ingreso en caja se guardan juntos, con su cola (RNF-04, RNF-08).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);

  late BaseLocalDrift base;
  late UnidadTrabajoDrift unidad;
  late ClienteRepositorioDrift clientes;
  late Fiado fiado;

  ServicioAbonos servicioAbonos({ICajaRepositorio? caja}) => ServicioAbonos(
    FiadoRepositorioDrift(base),
    ServicioCaja(caja ?? CajaRepositorioDrift(base)),
    unidad,
  );

  /// Lo que la base dice del cliente: así se recarga tras un error.
  Future<Fiado> recargar() async {
    final c = (await ServicioClientes(
      clientes,
    ).buscarClientes(tienda, 'maria')).single;
    return c.obtenerFiadosPendientes().single;
  }

  Future<int> contar(String tabla) async =>
      (await base.customSelect('SELECT COUNT(*) AS n FROM $tabla').getSingle())
          .read<int>('n');

  setUp(() async {
    base = BaseLocalDrift(NativeDatabase.memory());
    unidad = UnidadTrabajoDrift(base);
    final items = InventarioRepositorioDrift(base);
    final inventario = ServicioInventario(
      items,
      MovimientoInventarioRepositorioDrift(base),
      d('5'),
      unidad,
      ProductoRepositorioDrift(base),
    );
    clientes = ClienteRepositorioDrift(base);
    final arroz = Producto(
      'p-arroz',
      'ARR',
      'Arroz 500 g',
      UnidadMedida.unidad,
      d('2000'),
      d('2800'),
    );
    await ProductoRepositorioDrift(base).guardar(tienda, arroz);
    await items.guardarItem(tienda, ItemInventario('i-arroz', arroz, d('10')));
    final servicioFiados = ServicioFiados(FiadoRepositorioDrift(base));
    final ventas = ServicioVentas(
      inventario,
      [
        ProcesadorPagoContado(ServicioCaja(CajaRepositorioDrift(base))),
        ProcesadorNequi(),
        ProcesadorFiado(servicioFiados),
      ],
      VentaRepositorioDrift(base),
      unidad,
    );
    final maria = await ServicioClientes(clientes)
        .registrarCliente(tienda, 'María Pérez', '');
    final ls = <LineaVenta>[];
    await ventas.agregarLinea(tienda, ls, arroz, d('5')); // 14.000
    await ventas.confirmar(tienda, ls, [
      servicioFiados.crearFiado(maria, d('14000')),
    ]);
    fiado = await recargar();
    await base.delete(base.colaPendientes).go();
  });
  tearDown(() => base.close());

  test('abono en efectivo: guarda el abono, baja el saldo, entra a la caja y '
      'queda en la cola', () async {
    final abono = await servicioAbonos().registrarAbono(
      tienda,
      fiado,
      d('6000'),
      MedioPago.efectivo,
      null,
    );

    final fila = await base.select(base.abonos).getSingle();
    expect(fila.id, abono.getId());
    expect(fila.tiendaId, 't1');
    expect(fila.fiadoId, fiado.getId());
    expect(fila.monto, d('6000'));
    expect(fila.medio, 'EFECTIVO');
    expect(fila.referencia, isNull);
    expect(fila.anulado, isFalse);
    expect(fila.fecha.isUtc, isTrue);

    final filaFiado = await base.select(base.fiados).getSingle();
    expect(filaFiado.saldoPendiente, d('8000'));
    expect(filaFiado.estado, 'PENDIENTE');
    expect(filaFiado.montoInicial, d('14000'));

    final mov = await base.select(base.movimientosCaja).getSingle();
    expect((mov.valor, mov.descripcion), (d('6000'), 'Abono'));

    final cola = await base.select(base.colaPendientes).get();
    expect(
      cola.map((c) => (c.tabla, c.operacion)).toList()
        ..sort((a, b) => '${a.$1}${a.$2}'.compareTo('${b.$1}${b.$2}')),
      [
        ('abonos', 'INSERTAR'),
        ('cajas', 'INSERTAR'),
        ('fiados', 'ACTUALIZAR'),
        ('movimientos_caja', 'INSERTAR'),
      ],
    );
  });

  test('abono por Nequi que salda el fiado: SALDADO, con referencia y sin '
      'tocar la caja', () async {
    await servicioAbonos().registrarAbono(
      tienda,
      fiado,
      d('14000'),
      MedioPago.nequi,
      'N-123',
    );

    final fila = await base.select(base.abonos).getSingle();
    expect((fila.medio, fila.referencia), ('NEQUI', 'N-123'));
    final filaFiado = await base.select(base.fiados).getSingle();
    expect(filaFiado.saldoPendiente, Decimal.zero);
    expect(filaFiado.estado, 'SALDADO');
    expect(await contar('movimientos_caja'), 0);
    expect(await contar('cajas'), 0);
  });

  test('rollback real: si falla la caja no quedan ni el abono, ni el saldo '
      'cambiado, ni entradas en la cola', () async {
    await expectLater(
      servicioAbonos(caja: CajaQueFallaDespues(CajaRepositorioDrift(base)))
          .registrarAbono(tienda, fiado, d('6000'), MedioPago.efectivo, null),
      throwsA(isA<StateError>()),
    );

    expect(await contar('abonos'), 0);
    expect(await contar('movimientos_caja'), 0);
    expect(await contar('cola_pendientes'), 0);
    final filaFiado = await base.select(base.fiados).getSingle();
    expect(filaFiado.saldoPendiente, d('14000'));
    expect(filaFiado.estado, 'PENDIENTE');

    // El fiado en memoria quedó cambiado: se vuelve a leer de la base (DI-27).
    final recargado = await recargar();
    expect(recargado.getSaldoPendiente(), d('14000'));
    expect(recargado.getAbonos(), isEmpty);
  });

  test('buscar al cliente trae los abonos de cada fiado y su saldo', () async {
    await servicioAbonos().registrarAbono(
      tienda,
      fiado,
      d('4000'),
      MedioPago.efectivo,
      null,
    );
    await servicioAbonos().registrarAbono(
      tienda,
      fiado,
      d('1000'),
      MedioPago.nequi,
      'N-9',
    );

    final cliente = (await ServicioClientes(
      clientes,
    ).buscarClientes(tienda, 'perez')).single;
    final f = cliente.obtenerFiadosPendientes().single;
    expect(f.getSaldoPendiente(), d('9000'));
    expect(f.getEstado(), EstadoFiado.pendiente);
    expect(f.getAbonos().map((a) => a.getMonto()), [d('4000'), d('1000')]);
    expect(f.getAbonos().map((a) => a.getMedio()), [
      MedioPago.efectivo,
      MedioPago.nequi,
    ]);
    expect(f.getAbonos().last.getReferencia(), 'N-9');
    expect(cliente.calcularSaldoPendiente(), d('9000'));
  });
}
