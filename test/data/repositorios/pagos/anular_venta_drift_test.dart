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
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/cliente_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/fiado_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/venta_repositorio_drift.dart';
import 'package:gip/transversal/errores/errores_caja.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';

/// CUS-20 de punta a punta sobre la base local: ServicioVentas.anular con los
/// repositorios drift y la unidad de trabajo real (transacción y rollback).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otra = Tienda('t2', 'T002', 'Otra tienda', 'Turbaco');
  final propietario = Administrador('u1', 'Carmen Ruiz', '1000000001');
  Decimal d(String v) => Decimal.parse(v);

  late BaseLocalDrift base;
  late UnidadTrabajoDrift unidad;
  late InventarioRepositorioDrift items;
  late ServicioInventario inventario;
  late ServicioClientes servicioClientes;
  late ServicioFiados servicioFiados;
  late ServicioVentas ventas;
  late Producto arroz;
  late Producto cafe;

  setUp(() async {
    base = BaseLocalDrift(NativeDatabase.memory());
    unidad = UnidadTrabajoDrift(base);
    items = InventarioRepositorioDrift(base);
    inventario = ServicioInventario(
      items,
      MovimientoInventarioRepositorioDrift(base),
      d('5'),
      unidad,
      ProductoRepositorioDrift(base),
    );
    servicioClientes = ServicioClientes(ClienteRepositorioDrift(base));
    servicioFiados = ServicioFiados(FiadoRepositorioDrift(base));
    ventas = ServicioVentas(
      inventario,
      [
        ProcesadorPagoContado(ServicioCaja(CajaRepositorioDrift(base))),
        ProcesadorNequi(),
        ProcesadorFiado(servicioFiados),
      ],
      VentaRepositorioDrift(base),
      unidad,
    );
    arroz = Producto(
      'p-arroz',
      'ARR',
      'Arroz 500 g',
      UnidadMedida.unidad,
      d('2000'),
      d('2800'),
    );
    cafe = Producto(
      'p-cafe',
      'CAF',
      'Café molido 250 g',
      UnidadMedida.unidad,
      d('6000'),
      d('8900'),
    );
    final productos = ProductoRepositorioDrift(base);
    await productos.guardar(tienda, arroz);
    await productos.guardar(tienda, cafe);
    await items.guardarItem(tienda, ItemInventario('i-arroz', arroz, d('10')));
    await items.guardarItem(tienda, ItemInventario('i-cafe', cafe, d('21')));
  });
  tearDown(() => base.close());

  Future<Decimal> stock(Producto p) async =>
      (await items.buscarItem(tienda, p))!.getStockActual();

  Future<int> contar(String tabla) async =>
      (await base.customSelect('SELECT COUNT(*) AS n FROM $tabla').getSingle())
          .read<int>('n');

  Future<List<Venta>> leer() async {
    final ahora = DateTime.now();
    return VentaRepositorioDrift(base).listarPorPeriodo(
      tienda,
      ahora.subtract(const Duration(days: 1)),
      ahora.add(const Duration(days: 1)),
    );
  }

  /// Vende [cantidad] de arroz y de café con las formas que arme [formas].
  Future<Venta> vender(
    Future<List<dynamic>> Function(Decimal total) formas, {
    String arrozCant = '3',
    String cafeCant = '1',
  }) async {
    final lineas = <LineaVenta>[];
    await ventas.agregarLinea(tienda, lineas, arroz, d(arrozCant));
    await ventas.agregarLinea(tienda, lineas, cafe, d(cafeCant));
    final total = ventas.calcularTotal(lineas);
    return ventas.confirmar(tienda, lineas, (await formas(total)).cast());
  }

  Future<Venta> ventaDeContado() => vender(
    (total) async => [ventas.crearPagoContado(total, total)],
  ); // 3 x 2.800 + 8.900 = 17.300

  group('venta de contado', () {
    test('anula: guarda la anulación, devuelve el stock y saca el dinero de '
        'la caja de hoy', () async {
      final venta = await ventaDeContado();
      expect(await stock(arroz), d('7'));
      expect(await stock(cafe), d('20'));
      await base.delete(base.colaPendientes).go();

      final anulacion = await ventas.anular(
        tienda,
        venta,
        'Error al cobrar',
        propietario,
      );

      // La anulación quedó guardada y la venta la conoce.
      expect(venta.isAnulada(), isTrue);
      final fila = await base.select(base.anulacionesVenta).getSingle();
      expect(fila.id, anulacion.getId());
      expect(fila.ventaId, venta.getId());
      expect(fila.tiendaId, 't1');
      expect(fila.usuarioId, 'u1');
      expect(fila.usuarioNombre, 'Carmen Ruiz');
      expect(fila.motivo, 'Error al cobrar');
      expect(fila.fecha.isUtc, isTrue);

      // El stock volvió.
      expect(await stock(arroz), d('10'));
      expect(await stock(cafe), d('21'));
      final salidas = await base.select(base.movimientosInventario).get();
      expect(salidas, hasLength(2));
      expect(salidas.map((s) => s.estado), everyElement('ANULADO'));

      // El dinero salió de la caja de hoy como ANULACION.
      final mov = (await base.select(base.movimientosCaja).get());
      expect(mov, hasLength(2));
      final egreso = mov.firstWhere((m) => m.tipo == 'EGRESO');
      expect(egreso.clasificacion, 'ANULACION');
      expect(egreso.valor, d('17300'));
      final caja = await CajaRepositorioDrift(base)
          .buscarPorFecha(tienda, DateTime.now());
      expect(caja!.calcularSaldoEsperado(), Decimal.zero);

      // La venta no se tocó y la cola quedó con lo que hay que subir.
      final filaVenta = await base.select(base.ventas).getSingle();
      expect(filaVenta.total, d('17300'));
      final cola = await base.select(base.colaPendientes).get();
      expect(cola.map((e) => '${e.tabla}:${e.operacion}').toList()..sort(), [
        'anulaciones_venta:INSERTAR',
        'items_inventario:ACTUALIZAR',
        'items_inventario:ACTUALIZAR',
        'movimientos_caja:INSERTAR',
        'movimientos_inventario:ACTUALIZAR',
        'movimientos_inventario:ACTUALIZAR',
      ]);
    });

    test('al volver a leer la venta, trae su anulación', () async {
      final venta = await ventaDeContado();
      await ventas.anular(tienda, venta, 'Cliente devolvió', propietario);

      final leida = (await leer()).single;

      expect(leida.isAnulada(), isTrue);
      final anulacion = leida.getAnulacion()!;
      expect(anulacion.getMotivo(), 'Cliente devolvió');
      expect(anulacion.getUsuarioNombre(), 'Carmen Ruiz');
      expect(anulacion.getUsuarioId(), 'u1');
      expect(anulacion.getFecha().isUtc, isTrue);
    });

    test('una venta vigente se lee sin anulación', () async {
      await ventaDeContado();

      expect((await leer()).single.isAnulada(), isFalse);
    });

    test('rechaza una venta ya anulada y no repite nada', () async {
      final venta = await ventaDeContado();
      await ventas.anular(tienda, venta, 'Error al cobrar', propietario);

      await expectLater(
        ventas.anular(tienda, venta, 'Otra vez', propietario),
        throwsA(
          isA<ExcepcionVentaYaAnulada>().having(
            (e) => e.mensaje,
            'mensaje',
            'La venta ya estaba anulada',
          ),
        ),
      );
      // Tampoco si se vuelve a leer de la base.
      await expectLater(
        ventas.anular(tienda, (await leer()).single, 'Otra', propietario),
        throwsA(isA<ExcepcionVentaYaAnulada>()),
      );
      expect(await contar('anulaciones_venta'), 1);
      expect(await stock(arroz), d('10'));
    });

    test('un motivo vacío se rechaza sin guardar nada', () async {
      final venta = await ventaDeContado();

      for (final motivo in ['', '   ']) {
        await expectLater(
          ventas.anular(tienda, venta, motivo, propietario),
          throwsA(isA<ExcepcionMotivoAnulacionObligatorio>()),
        );
      }
      expect(venta.isAnulada(), isFalse);
      expect(await contar('anulaciones_venta'), 0);
      expect(await stock(arroz), d('7'));
    });

    test('guarda el motivo sin espacios sobrantes', () async {
      final venta = await ventaDeContado();

      final a = await ventas.anular(
        tienda,
        venta,
        '  Otro: error  ',
        propietario,
      );

      expect(a.getMotivo(), 'Otro: error');
    });
  });

  group('rollback: si algo falla no se guarda nada', () {
    test('con la caja de hoy cerrada no se anula', () async {
      final venta = await ventaDeContado();
      await ServicioCaja(CajaRepositorioDrift(base))
          .cerrarCaja(tienda, d('17300'));
      final antes = {
        for (final t in [
          'anulaciones_venta',
          'movimientos_inventario',
          'movimientos_caja',
        ])
          t: await contar(t),
      };

      await expectLater(
        ventas.anular(tienda, venta, 'Error al cobrar', propietario),
        throwsA(
          isA<ExcepcionCajaCerrada>().having(
            (e) => e.mensaje,
            'mensaje',
            'La caja de hoy ya está cerrada',
          ),
        ),
      );

      // Ni la anulación, ni el stock, ni los movimientos cambiaron.
      expect(venta.isAnulada(), isFalse);
      expect(await contar('anulaciones_venta'), antes['anulaciones_venta']);
      expect(await contar('movimientos_caja'), antes['movimientos_caja']);
      expect(await stock(arroz), d('7'));
      expect(await stock(cafe), d('20'));
      final salidas = await base.select(base.movimientosInventario).get();
      expect(salidas.map((s) => s.estado), everyElement('VIGENTE'));
    });
  });

  group('venta fiada', () {
    Future<Venta> ventaFiada() async {
      final maria = await servicioClientes.registrarCliente(
        tienda,
        'María Pérez',
        '',
      );
      return vender(
        (total) async => [servicioFiados.crearFiado(maria, total)],
        arrozCant: '2',
        cafeCant: '0.5',
      );
    }

    test(
      'anula el fiado (saldo cero, estado ANULADO) y no mueve la caja',
      () async {
        final venta = await ventaFiada();
        await base.delete(base.colaPendientes).go();

        await ventas.anular(tienda, venta, 'Error al cobrar', propietario);

        final fila = await base.select(base.fiados).getSingle();
        expect(fila.estado, 'ANULADO');
        expect(fila.saldoPendiente, Decimal.zero);
        expect(fila.montoInicial, d('10050'));
        expect(await contar('movimientos_caja'), 0);
        expect(await stock(arroz), d('10'));
        final cola = await base.select(base.colaPendientes).get();
        expect(cola.where((e) => e.tabla == 'fiados').map((e) => e.operacion), [
          'ACTUALIZAR',
        ]);
      },
    );

    test(
      'si el fiado ya tiene abonos no se puede anular y no cambia nada',
      () async {
        final venta = await ventaFiada();
        final fiado = (await leer()).single.getFormasPago().single;
        await ServicioAbonos(
          FiadoRepositorioDrift(base),
          ServicioCaja(CajaRepositorioDrift(base)),
          unidad,
        ).registrarAbono(
          tienda,
          (fiado as dynamic),
          d('1000'),
          MedioPago.efectivo,
          null,
        );
        final antes = await contar('movimientos_caja');

        // Se vuelve a leer: el fiado trae sus abonos.
        final leida = (await leer()).single;
        await expectLater(
          ventas.anular(tienda, leida, 'Error al cobrar', propietario),
          throwsA(
            isA<ExcepcionFiadoConAbonos>().having(
              (e) => e.mensaje,
              'mensaje',
              'No se puede anular la venta: el fiado ya tiene abonos',
            ),
          ),
        );

        expect(venta.getId(), leida.getId());
        expect(await contar('anulaciones_venta'), 0);
        expect(await contar('movimientos_caja'), antes);
        expect(await stock(arroz), d('8'));
        final filaFiado = await base.select(base.fiados).getSingle();
        expect(filaFiado.estado, 'PENDIENTE');
        expect(filaFiado.saldoPendiente, d('9050'));
        final salidas = await base.select(base.movimientosInventario).get();
        expect(salidas.map((s) => s.estado), everyElement('VIGENTE'));
      },
    );
  });

  group('venta por Nequi y mixta', () {
    test('Nequi no mueve la caja', () async {
      final venta = await vender(
        (total) async => [ventas.crearPagoNequi(total, '4471')],
      );

      await ventas.anular(tienda, venta, 'Error al cobrar', propietario);

      expect(await contar('movimientos_caja'), 0);
      expect(venta.isAnulada(), isTrue);
      expect(await stock(arroz), d('10'));
    });

    test('una venta mixta revierte solo lo que entró a la caja', () async {
      final maria = await servicioClientes.registrarCliente(
        tienda,
        'María Pérez',
        '',
      );
      final venta = await vender(
        (total) async => [
          ventas.crearPagoContado(d('7300'), d('10000')), // cambio 2.700
          ventas.crearPagoNequi(d('5000'), null),
          servicioFiados.crearFiado(maria, d('5000')),
        ],
      );

      await ventas.anular(tienda, venta, 'Cliente devolvió', propietario);

      final egreso = (await base.select(base.movimientosCaja).get()).firstWhere(
        (m) => m.tipo == 'EGRESO',
      );
      expect(egreso.valor, d('7300'));
      expect(egreso.clasificacion, 'ANULACION');
      final fiado = await base.select(base.fiados).getSingle();
      expect(fiado.estado, 'ANULADO');
      expect(await stock(cafe), d('21'));
    });
  });

  group('listar y consultar', () {
    test('listarVentas trae las vigentes y las anuladas', () async {
      final a = await ventaDeContado();
      await ventaDeContado();
      await ventas.anular(tienda, a, 'Error al cobrar', propietario);

      final ahora = DateTime.now();
      final lista = await ventas.listarVentas(
        tienda,
        ahora.subtract(const Duration(days: 1)),
        ahora.add(const Duration(days: 1)),
      );

      expect(lista, hasLength(2));
      expect(lista.where((v) => v.isAnulada()), hasLength(1));
    });

    test('listarSalidas trae los productos de cada venta, también de las '
        'anuladas', () async {
      final a = await ventaDeContado();
      final b = await vender(
        (total) async => [ventas.crearPagoContado(total, total)],
        arrozCant: '1',
        cafeCant: '2',
      );
      await ventas.anular(tienda, a, 'Error al cobrar', propietario);

      final salidas = await ventas.listarSalidas(tienda, await leer());

      expect(
        salidas[a.getId()]!.map((s) => s.getItem().getProducto().getNombre()),
        unorderedEquals(['Arroz 500 g', 'Café molido 250 g']),
      );
      expect(
        salidas[a.getId()]!.every(
          (s) => s.getEstado() == EstadoMovimiento.anulado,
        ),
        isTrue,
      );
      expect(
        salidas[b.getId()]!.every(
          (s) => s.getEstado() == EstadoMovimiento.vigente,
        ),
        isTrue,
      );
      expect(salidas[b.getId()]!, hasLength(2));
    });

    test('cada tienda ve solo lo suyo', () async {
      await ventaDeContado();

      final ahora = DateTime.now();
      final deOtra = await ventas.listarVentas(
        otra,
        ahora.subtract(const Duration(days: 1)),
        ahora.add(const Duration(days: 1)),
      );
      expect(deOtra, isEmpty);
      expect(await ventas.listarSalidas(otra, await leer()), isEmpty);
    });
  });
}
