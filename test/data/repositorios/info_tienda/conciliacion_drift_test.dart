import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_abono_excedido.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_caja_cerrada.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_codigo_repetido.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_movimientos.dart';
import 'package:gip/business/componentes/info_tienda/servicio_conciliacion.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_inventario/ajuste_conteo.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/info_tienda/i_conflicto_repositorio.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/movimiento_inventario_repositorio_drift.dart';
import 'package:gip/data/repositorios/gestion_inventario/producto_repositorio_drift.dart';
import 'package:gip/data/repositorios/info_tienda/conflicto_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/cliente_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/fiado_repositorio_drift.dart';
import 'package:gip/data/repositorios/pagos/venta_repositorio_drift.dart';
import 'package:gip/transversal/errores/errores_caja.dart';

/// Lo que CUS-22 necesita de los repositorios drift, y el servicio de
/// conciliación de punta a punta con la unidad de trabajo real (transacción y
/// rollback) (DI-45).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otra = Tienda('t2', 'T002', 'Otra tienda', 'Turbaco');
  Decimal d(String v) => Decimal.parse(v);
  final fecha = DateTime.utc(2026, 11, 19, 15, 42);

  late BaseLocalDrift base;
  late UnidadTrabajoDrift unidad;
  late InventarioRepositorioDrift items;
  late MovimientoInventarioRepositorioDrift movimientos;
  late ProductoRepositorioDrift productos;
  late ClienteRepositorioDrift clientes;
  late VentaRepositorioDrift ventas;
  late FiadoRepositorioDrift fiados;
  late CajaRepositorioDrift cajas;
  late ConflictoRepositorioDrift conflictos;
  late ServicioCaja servicioCaja;
  late ServicioInventario inventario;
  late Producto huevo;
  late ItemInventario itemHuevo;

  ServicioConciliacion servicio([IConflictoRepositorio? repoConflictos]) =>
      ServicioConciliacion(repoConflictos ?? conflictos, unidad, [
        ResolutorMovimientos(movimientos, inventario),
        ResolutorAbonoExcedido(fiados, servicioCaja),
        ResolutorCodigoRepetido(productos),
        ResolutorCajaCerrada(cajas),
      ]);

  setUp(() async {
    base = BaseLocalDrift(NativeDatabase.memory());
    unidad = UnidadTrabajoDrift(base);
    items = InventarioRepositorioDrift(base);
    movimientos = MovimientoInventarioRepositorioDrift(base);
    productos = ProductoRepositorioDrift(base);
    clientes = ClienteRepositorioDrift(base);
    ventas = VentaRepositorioDrift(base);
    fiados = FiadoRepositorioDrift(base);
    cajas = CajaRepositorioDrift(base);
    conflictos = ConflictoRepositorioDrift(base);
    servicioCaja = ServicioCaja(cajas);
    inventario = ServicioInventario(
      items,
      movimientos,
      d('5'),
      unidad,
      productos,
    );
    huevo = Producto(
      'p-huevo',
      'H1',
      'Huevo AA',
      UnidadMedida.unidad,
      d('400'),
      d('550'),
    );
    await productos.guardar(tienda, huevo);
    // El stock guardado es el de antes de unir los registros de los equipos.
    itemHuevo = ItemInventario('i-huevo', huevo, d('48'));
    await items.guardarItem(tienda, itemHuevo);
  });
  tearDown(() => base.close());

  Future<int> contar(String tabla) async =>
      (await base.customSelect('SELECT COUNT(*) AS n FROM $tabla').getSingle())
          .read<int>('n');

  Future<List<String>> cola(String tabla) async => [
    for (final f in await base.select(base.colaPendientes).get())
      if (f.tabla == tabla) '${f.operacion}:${f.registroId}',
  ];

  Future<Decimal> stock() async =>
      (await items.buscarItem(tienda, huevo))!.getStockActual();

  Future<EstadoMovimiento> estado(String id) async =>
      (await movimientos.buscarPorIds(tienda, [id])).single.getEstado();

  Future<EntradaMercancia> entrada(
    String id, {
    String cantidad = '24',
    EstadoMovimiento estadoInicial = EstadoMovimiento.vigente,
    Tienda? t,
  }) async {
    final e = EntradaMercancia(
      id,
      itemHuevo,
      d(cantidad),
      fecha,
      d('400'),
      'FV-1',
    )..setEstado(estadoInicial);
    await movimientos.guardar(t ?? tienda, e);
    return e;
  }

  group('IMovimientoInventarioRepositorio.buscarPorIds', () {
    test('trae los movimientos pedidos de cualquier tipo y estado, con su '
        'ítem y su producto', () async {
      await entrada('e1');
      await entrada('e2', estadoInicial: EstadoMovimiento.enRevision);
      await entrada('e3', estadoInicial: EstadoMovimiento.anulado);
      await movimientos.guardar(
        tienda,
        Merma('m1', itemHuevo, -d('2'), fecha, MotivoMerma.vencido),
      );
      await movimientos.guardar(
        tienda,
        AjusteConteo('a1', itemHuevo, -d('1'), fecha, d('45')),
      );
      final venta = Venta(
        'v1',
        [PagoContado('pc1', d('550'), Decimal.zero)],
        d('550'),
        fecha,
      );
      await ventas.guardar(tienda, venta);
      await movimientos.guardar(
        tienda,
        SalidaVenta('s1', itemHuevo, -d('1'), fecha, venta, d('550'), d('400')),
      );

      final lista = await movimientos.buscarPorIds(tienda, [
        'e1',
        'e2',
        'e3',
        'm1',
        'a1',
        's1',
      ]);

      expect(lista.map((m) => m.getId()).toSet(), {
        'e1',
        'e2',
        'e3',
        'm1',
        'a1',
        's1',
      });
      expect(
        lista.firstWhere((m) => m.getId() == 'e2').getEstado(),
        EstadoMovimiento.enRevision,
      );
      expect(
        lista.firstWhere((m) => m.getId() == 'e3').getEstado(),
        EstadoMovimiento.anulado,
      );
      expect(lista.firstWhere((m) => m.getId() == 's1'), isA<SalidaVenta>());
      expect(lista.firstWhere((m) => m.getId() == 'm1'), isA<Merma>());
      expect(lista.firstWhere((m) => m.getId() == 'a1'), isA<AjusteConteo>());
      final item = lista.first.getItem();
      expect(item.getId(), 'i-huevo');
      expect(item.getProducto().getNombre(), 'Huevo AA');
      expect(item.getStockActual(), d('48'));
    });

    test('los movimientos del mismo ítem comparten el mismo ítem', () async {
      await entrada('e1');
      await entrada('e2');

      final lista = await movimientos.buscarPorIds(tienda, ['e1', 'e2']);

      expect(identical(lista[0].getItem(), lista[1].getItem()), isTrue);
    });

    test('los ids que no existen no aparecen y una lista vacía devuelve '
        'vacío', () async {
      await entrada('e1');

      expect(
        (await movimientos.buscarPorIds(tienda, [
          'e1',
          'fantasma',
        ])).map((m) => m.getId()),
        ['e1'],
      );
      expect(await movimientos.buscarPorIds(tienda, const []), isEmpty);
    });

    test('solo los de la tienda pedida', () async {
      await entrada('e1');

      expect(await movimientos.buscarPorIds(otra, ['e1']), isEmpty);
    });
  });

  group('IFiadoRepositorio.buscarPorId y anularAbono', () {
    Future<Fiado> fiadoConDosAbonos() async {
      final cliente = Cliente('c1', 'María Pérez', '300 412 4521');
      await clientes.guardar(tienda, cliente);
      final fiado = Fiado('f1', d('10000'), fecha, cliente);
      await ventas.guardar(tienda, Venta('v-f1', [fiado], d('10000'), fecha));
      await fiados.crear(tienda, fiado);
      // Un equipo recibe 8.000...
      final a1 = Abono('a1', d('8000'), fecha, MedioPago.efectivo, null);
      fiado.registrarAbono(a1);
      await fiados.registrarAbono(tienda, fiado, a1);
      // ...y otro, sin saberlo, otros 8.000: al unirlos sobran 6.000.
      final a2 = Abono(
        'a2',
        d('8000'),
        fecha.add(const Duration(minutes: 1)),
        MedioPago.nequi,
        null,
      );
      final delOtro = Fiado.guardado(
        'f1',
        d('10000'),
        fecha,
        cliente,
        d('-6000'),
        EstadoFiado.saldado,
        [a1, a2],
      );
      await fiados.registrarAbono(tienda, delOtro, a2);
      await base.delete(base.colaPendientes).go();
      return delOtro;
    }

    test('buscarPorId trae el fiado con su cliente y sus abonos del más '
        'antiguo al más reciente', () async {
      await fiadoConDosAbonos();

      final f = (await fiados.buscarPorId(tienda, 'f1'))!;

      expect(f.getMontoInicial(), d('10000'));
      expect(f.getSaldoPendiente(), d('-6000'));
      expect(f.getEstado(), EstadoFiado.saldado);
      expect(f.getCliente().getNombre(), 'María Pérez');
      expect(f.getAbonos().map((a) => a.getId()), ['a1', 'a2']);
      expect(f.getAbonos().last.getMedio(), MedioPago.nequi);
    });

    test('buscarPorId incluye los abonos anulados', () async {
      final f0 = await fiadoConDosAbonos();
      final a2 = f0.getAbonos().last..anular();
      await fiados.anularAbono(tienda, f0, a2);

      final f = (await fiados.buscarPorId(tienda, 'f1'))!;

      expect(f.getAbonos().map((a) => a.isAnulado()), [false, true]);
    });

    test(
      'buscarPorId devuelve nulo si no existe o es de otra tienda',
      () async {
        await fiadoConDosAbonos();

        expect(await fiados.buscarPorId(tienda, 'fantasma'), isNull);
        expect(await fiados.buscarPorId(otra, 'f1'), isNull);
      },
    );

    test('anularAbono marca solo ese abono y anota el ACTUALIZAR; no toca el '
        'saldo ni los demás abonos', () async {
      final f0 = await fiadoConDosAbonos();
      final a2 = f0.getAbonos().last..anular();

      await fiados.anularAbono(tienda, f0, a2);

      final filas = await base.select(base.abonos).get();
      expect(
        {for (final f in filas) f.id: f.anulado},
        {'a1': false, 'a2': true},
      );
      final fila = await base.select(base.fiados).getSingle();
      expect(fila.saldoPendiente, d('-6000'));
      expect(await cola('abonos'), ['ACTUALIZAR:a2']);
      expect(await cola('fiados'), isEmpty);
    });

    test('anularAbono con la tienda equivocada no cambia nada', () async {
      final f0 = await fiadoConDosAbonos();
      final a2 = f0.getAbonos().last..anular();

      await fiados.anularAbono(otra, f0, a2);

      final filas = await base.select(base.abonos).get();
      expect(filas.any((f) => f.anulado), isFalse);
    });
  });

  group('ICajaRepositorio.buscarPorId', () {
    final dia = DateTime(2026, 11, 14);
    final idCaja = ServicioCaja.idCaja(tienda, dia);

    MovimientoCaja ingreso(String id, String valor) => MovimientoCaja(
      id,
      d(valor),
      'Venta',
      ClasificacionMovimiento.negocio,
      TipoMovimientoCaja.ingreso,
      DateTime.utc(2026, 11, 14, 15),
    );

    test('trae la caja con todos sus movimientos, también los que llegaron '
        'después del cierre, y los datos del cierre', () async {
      final caja = Caja(idCaja, dia);
      await cajas.crear(tienda, caja);
      await cajas.registrarMovimiento(
        tienda,
        caja,
        caja.registrarMovimiento(ingreso('m1', '30000')),
      );
      caja.cerrar(d('30000'));
      await cajas.cerrar(tienda, caja);
      await cajas.registrarMovimiento(tienda, caja, ingreso('m2', '2000'));

      final leida = (await cajas.buscarPorId(tienda, idCaja))!;

      expect(leida.getId(), idCaja);
      expect(leida.isCerrada(), isTrue);
      expect(leida.getEfectivoContado(), d('30000'));
      expect(leida.getDiferencia(), Decimal.zero);
      expect(leida.getMovimientos().map((m) => m.getId()), ['m1', 'm2']);
      expect(leida.calcularSaldoEsperado(), d('32000'));
    });

    test('devuelve nulo si no existe o es de otra tienda', () async {
      await cajas.crear(tienda, Caja(idCaja, dia));

      expect(await cajas.buscarPorId(tienda, 'fantasma'), isNull);
      expect(await cajas.buscarPorId(otra, idCaja), isNull);
    });
  });

  group('IProductoRepositorio.quitarCodigo', () {
    CodigoProducto codigo(String id, String valor) =>
        CodigoProducto(id, FormatoCodigo.ean13, valor);

    test('borra solo ese código y anota el ELIMINAR; el producto y sus otros '
        'códigos siguen', () async {
      final p =
          Producto('p1', 'A-1', 'Arroz', UnidadMedida.unidad, d('1'), d('2'))
            ..agregarCodigo(codigo('c1', '7701234567895'))
            ..agregarCodigo(codigo('c2', '7709999999999'));
      await productos.guardar(tienda, p);
      await base.delete(base.colaPendientes).go();

      await productos.quitarCodigo(tienda, p, codigo('c1', '7701234567895'));

      final leido = (await productos.buscarPorId(tienda, 'p1'))!;
      expect(leido.getCodigos().map((c) => c.getId()), ['c2']);
      expect(await cola('codigos_producto'), ['ELIMINAR:c1']);
      expect(await cola('productos'), isEmpty);
    });

    test('no borra el mismo valor de otro producto', () async {
      final p1 = Producto(
        'p1',
        'A-1',
        'Uno',
        UnidadMedida.unidad,
        d('1'),
        d('2'),
      )..agregarCodigo(codigo('c1', '7701234567895'));
      final p2 = Producto(
        'p2',
        'B-1',
        'Dos',
        UnidadMedida.unidad,
        d('1'),
        d('2'),
      )..agregarCodigo(codigo('c2', '7701234567895'));
      await productos.guardar(tienda, p1);
      await productos.guardar(tienda, p2);

      await productos.quitarCodigo(tienda, p2, codigo('c2', '7701234567895'));

      expect(
        (await productos.buscarPorId(tienda, 'p1'))!.getCodigos(),
        hasLength(1),
      );
      expect(
        (await productos.buscarPorId(tienda, 'p2'))!.getCodigos(),
        isEmpty,
      );
    });

    test('un código que no existe no anota nada en la cola', () async {
      final p = Producto(
        'p1',
        'A-1',
        'Uno',
        UnidadMedida.unidad,
        d('1'),
        d('2'),
      );
      await productos.guardar(tienda, p);
      await base.delete(base.colaPendientes).go();

      await productos.quitarCodigo(tienda, p, codigo('nada', 'x'));

      expect(await contar('cola_pendientes'), 0);
    });

    test('con la tienda equivocada no borra nada', () async {
      final p = Producto(
        'p1',
        'A-1',
        'Uno',
        UnidadMedida.unidad,
        d('1'),
        d('2'),
      )..agregarCodigo(codigo('c1', '7701234567895'));
      await productos.guardar(tienda, p);

      await productos.quitarCodigo(otra, p, codigo('c1', '7701234567895'));

      expect(await contar('codigos_producto'), 1);
    });

    test(
      'guardar un producto leído sin códigos sigue sin borrarlos (DI-34)',
      () async {
        final p = Producto(
          'p1',
          'A-1',
          'Uno',
          UnidadMedida.unidad,
          d('1'),
          d('2'),
        )..agregarCodigo(codigo('c1', '7701234567895'));
        await productos.guardar(tienda, p);
        final sinCodigos = Producto(
          'p1',
          'A-1',
          'Uno',
          UnidadMedida.unidad,
          d('1'),
          d('2'),
        );

        await productos.guardar(tienda, sinCodigos);

        expect(await contar('codigos_producto'), 1);
      },
    );

    test('cambiar el código interno y guardar lo actualiza', () async {
      final p = Producto(
        'p1',
        'GAL-6',
        'Uno',
        UnidadMedida.unidad,
        d('1'),
        d('2'),
      );
      await productos.guardar(tienda, p);

      p.cambiarCodigoInterno('GAL-6-2');
      await productos.guardar(tienda, p);

      expect(
        (await productos.buscarPorId(tienda, 'p1'))!.getCodigo(),
        'GAL-6-2',
      );
      expect(await productos.buscarPorCodigo(tienda, 'GAL-6'), isNull);
    });
  });

  group('resolver conflictos con la base local', () {
    Future<ConflictoSincronizacion> sembrar(
      TipoConflicto tipo,
      List<String> ids,
    ) async {
      final c = ConflictoSincronizacion(
        '${tipo.name}:${ids.join(':')}',
        tipo,
        'Descripción',
        ids,
        fecha,
      );
      await conflictos.guardar(tienda, c);
      await base.delete(base.colaPendientes).go();
      return c;
    }

    test('entradas repetidas: anula la elegida, deja vigente la otra, '
        'recalcula el stock y cierra el conflicto', () async {
      await entrada('e1');
      await entrada('e2', estadoInicial: EstadoMovimiento.enRevision);
      final c = await sembrar(TipoConflicto.posibleDuplicado, ['e1', 'e2']);

      await servicio().resolverConflicto(tienda, c, ['e2']);

      expect(await estado('e1'), EstadoMovimiento.vigente);
      expect(await estado('e2'), EstadoMovimiento.anulado);
      expect(await stock(), d('24'));
      expect(await conflictos.listarPendientes(tienda), isEmpty);
      expect(await cola('movimientos_inventario'), contains('ACTUALIZAR:e2'));
      expect(await cola('items_inventario'), ['ACTUALIZAR:i-huevo']);
      expect(await cola('conflictos_sincronizacion'), [
        'ACTUALIZAR:${c.getId()}',
      ]);
    });

    test(
      '"fueron distintas": las dos quedan vigentes y el stock las suma',
      () async {
        await entrada('e1');
        await entrada('e2', estadoInicial: EstadoMovimiento.enRevision);
        final c = await sembrar(TipoConflicto.posibleDuplicado, ['e1', 'e2']);

        await servicio().resolverConflicto(tienda, c, const []);

        expect(await estado('e2'), EstadoMovimiento.vigente);
        expect(await stock(), d('48'));
      },
    );

    test('si marcarResuelto falla se deshace todo: estados, stock y conflicto '
        'quedan como estaban y no queda nada en la cola', () async {
      await entrada('e1');
      await entrada('e2', estadoInicial: EstadoMovimiento.enRevision);
      final c = await sembrar(TipoConflicto.posibleDuplicado, ['e1', 'e2']);

      await expectLater(
        servicio(_ConflictosQueFallanAlMarcar(conflictos))
            .resolverConflicto(tienda, c, ['e2']),
        throwsA(isA<StateError>()),
      );

      expect(await estado('e2'), EstadoMovimiento.enRevision);
      expect(await stock(), d('48'));
      expect(await conflictos.listarPendientes(tienda), hasLength(1));
      expect(c.isResuelto(), isFalse);
      expect(await contar('cola_pendientes'), 0);
    });

    test('stock negativo: "aceptar así" cierra el conflicto y el stock queda '
        'como lo dicen los movimientos', () async {
      await entrada('e1', cantidad: '4');
      final venta = Venta(
        'v1',
        [PagoContado('pc1', d('5500'), Decimal.zero)],
        d('5500'),
        fecha,
      );
      await ventas.guardar(tienda, venta);
      await movimientos.guardar(
        tienda,
        SalidaVenta(
          's1',
          itemHuevo,
          -d('10'),
          fecha,
          venta,
          d('550'),
          d('400'),
        ),
      );
      final c = await sembrar(TipoConflicto.stockNegativo, ['e1', 's1']);

      await servicio().resolverConflicto(tienda, c, const []);

      expect(await stock(), d('-6'));
      expect(await conflictos.listarPendientes(tienda), isEmpty);
    });

    group('abono mayor que el saldo', () {
      Future<void> fiadoConAbonoDeMas() async {
        final cliente = Cliente('c1', 'María Pérez', '');
        await clientes.guardar(tienda, cliente);
        final fiado = Fiado('f1', d('10000'), fecha, cliente);
        await ventas.guardar(tienda, Venta('v-f1', [fiado], d('10000'), fecha));
        await fiados.crear(tienda, fiado);
        final a1 = Abono('a1', d('8000'), fecha, MedioPago.efectivo, null);
        fiado.registrarAbono(a1);
        await fiados.registrarAbono(tienda, fiado, a1);
        final a2 = Abono('a2', d('8000'), fecha, MedioPago.efectivo, null);
        await fiados.registrarAbono(
          tienda,
          Fiado.guardado(
            'f1',
            d('10000'),
            fecha,
            cliente,
            d('-6000'),
            EstadoFiado.saldado,
            [a1, a2],
          ),
          a2,
        );
        await base.delete(base.colaPendientes).go();
      }

      test('anula el abono, devuelve el efectivo por la caja de hoy y deja el '
          'saldo bien', () async {
        await fiadoConAbonoDeMas();
        final c = await sembrar(TipoConflicto.abonoExcedeSaldo, [
          'f1',
          'a1',
          'a2',
        ]);

        await servicio().resolverConflicto(tienda, c, ['a2']);

        final abonos = await base.select(base.abonos).get();
        expect(
          {for (final a in abonos) a.id: a.anulado},
          {'a1': false, 'a2': true},
        );
        final fila = await base.select(base.fiados).getSingle();
        expect(fila.saldoPendiente, d('2000'));
        expect(fila.estado, 'PENDIENTE');
        final hoy = await servicioCaja.consultarCajaDelDia(tienda);
        final movimiento = hoy.getMovimientos().single;
        expect(movimiento.getValor(), d('8000'));
        expect(movimiento.getTipo(), TipoMovimientoCaja.egreso);
        expect(
          movimiento.getClasificacion(),
          ClasificacionMovimiento.anulacion,
        );
        expect(await conflictos.listarPendientes(tienda), isEmpty);
      });

      test('si la caja de hoy está cerrada, se deshace todo: el abono sigue '
          'sin anular y el saldo y el conflicto quedan como estaban', () async {
        await fiadoConAbonoDeMas();
        final c = await sembrar(TipoConflicto.abonoExcedeSaldo, [
          'f1',
          'a1',
          'a2',
        ]);
        await servicioCaja.cerrarCaja(tienda, Decimal.zero);
        await base.delete(base.colaPendientes).go();

        await expectLater(
          servicio().resolverConflicto(tienda, c, ['a2']),
          throwsA(isA<ExcepcionCajaCerrada>()),
        );

        final abonos = await base.select(base.abonos).get();
        expect(abonos.any((a) => a.anulado), isFalse);
        expect(
          (await base.select(base.fiados).getSingle()).saldoPendiente,
          d('-6000'),
        );
        expect(await conflictos.listarPendientes(tienda), hasLength(1));
        expect(await contar('cola_pendientes'), 0);
      });

      test('si los abonos elegidos no bastan, no se escribe nada', () async {
        await fiadoConAbonoDeMas();
        final c = await sembrar(TipoConflicto.abonoExcedeSaldo, [
          'f1',
          'a1',
          'a2',
        ]);

        await expectLater(
          servicio().resolverConflicto(tienda, c, const []),
          throwsA(isA<Exception>()),
        );

        expect(await conflictos.listarPendientes(tienda), hasLength(1));
        expect(await contar('cola_pendientes'), 0);
      });
    });

    test(
      'movimiento en caja cerrada: recalcula la diferencia y la guarda',
      () async {
        final dia = DateTime(2026, 11, 14);
        final idCaja = ServicioCaja.idCaja(tienda, dia);
        final caja = Caja(idCaja, dia);
        await cajas.crear(tienda, caja);
        await cajas.registrarMovimiento(
          tienda,
          caja,
          caja.registrarMovimiento(
            MovimientoCaja(
              'm1',
              d('30000'),
              'Venta',
              ClasificacionMovimiento.negocio,
              TipoMovimientoCaja.ingreso,
              DateTime.utc(2026, 11, 14, 15),
            ),
          ),
        );
        caja.cerrar(d('30000'));
        await cajas.cerrar(tienda, caja);
        await cajas.registrarMovimiento(
          tienda,
          caja,
          MovimientoCaja(
            'm2',
            d('2000'),
            'Venta',
            ClasificacionMovimiento.negocio,
            TipoMovimientoCaja.ingreso,
            DateTime.utc(2026, 11, 14, 23, 30),
          ),
        );
        final c = await sembrar(TipoConflicto.movimientoCajaCerrada, [
          idCaja,
          'm2',
        ]);

        await servicio().resolverConflicto(tienda, c, const []);

        final fila = await base.select(base.cajas).getSingle();
        expect(fila.diferencia, d('-2000'));
        expect(fila.efectivoContado, d('30000'));
        expect(fila.cerrada, isTrue);
        expect(await cola('cajas'), ['ACTUALIZAR:$idCaja']);
        expect(await conflictos.listarPendientes(tienda), isEmpty);
      },
    );

    test('código repetido: quita el código de barras del producto elegido y '
        'cambia su código interno', () async {
      Producto conCodigo(String id, String idCodigo) =>
          Producto(
            id,
            'GAL-6',
            'Galletas $id',
            UnidadMedida.unidad,
            d('1'),
            d('2'),
          )..agregarCodigo(
            CodigoProducto(idCodigo, FormatoCodigo.ean13, '7701234567895'),
          );
      final p1 = conCodigo('p-uno', 'c1');
      final p2 = conCodigo('p-dos', 'c2');
      await productos.guardar(tienda, p1);
      await productos.guardar(tienda, p2);
      final c = await sembrar(TipoConflicto.codigoRepetido, ['p-uno', 'p-dos']);

      await servicio().resolverConflicto(tienda, c, ['p-dos']);

      final uno = (await productos.buscarPorId(tienda, 'p-uno'))!;
      final dos = (await productos.buscarPorId(tienda, 'p-dos'))!;
      expect(uno.getCodigos(), hasLength(1));
      expect(uno.getCodigo(), 'GAL-6');
      expect(dos.getCodigos(), isEmpty);
      expect(dos.getCodigo(), 'GAL-6-2');
      expect(await cola('codigos_producto'), ['ELIMINAR:c2']);
      expect(await conflictos.listarPendientes(tienda), isEmpty);
    });
  });
}

/// Marca el conflicto de verdad y luego falla, para probar que el rollback
/// también deshace lo que ya se escribió.
class _ConflictosQueFallanAlMarcar implements IConflictoRepositorio {
  _ConflictosQueFallanAlMarcar(this._real);

  final IConflictoRepositorio _real;

  @override
  Future<void> guardar(Tienda tienda, ConflictoSincronizacion conflicto) =>
      _real.guardar(tienda, conflicto);

  @override
  Future<List<ConflictoSincronizacion>> listarPendientes(Tienda tienda) =>
      _real.listarPendientes(tienda);

  @override
  Future<void> marcarResuelto(
    Tienda tienda,
    ConflictoSincronizacion conflicto,
  ) async {
    await _real.marcarResuelto(tienda, conflicto);
    throw StateError('falla del disco');
  }
}
