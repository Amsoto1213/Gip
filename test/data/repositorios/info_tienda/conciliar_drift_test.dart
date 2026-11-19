import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
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

/// Lo que CUS-23 necesita de los repositorios drift y la conciliación de
/// punta a punta con la unidad de trabajo real (DI-46).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otra = Tienda('t2', 'T002', 'Otra tienda', 'Turbaco');
  Decimal d(String v) => Decimal.parse(v);

  final desde = DateTime.utc(2026, 11, 19, 14);
  final f1 = DateTime.utc(2026, 11, 19, 15);
  final f2 = DateTime.utc(2026, 11, 19, 16);
  final ahora = DateTime.utc(2026, 11, 19, 20);

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
  late ServicioInventario inventario;
  late Producto huevo;
  late ItemInventario itemHuevo;

  ServicioConciliacion servicio([IConflictoRepositorio? repoConflictos]) =>
      ServicioConciliacion(
        repoConflictos ?? conflictos,
        movimientos,
        fiados,
        cajas,
        productos,
        inventario,
        unidad,
        const [],
        reloj: () => ahora,
      );

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
    itemHuevo = ItemInventario('i-huevo', huevo, d('999'));
    await items.guardarItem(tienda, itemHuevo);
    await base.delete(base.colaPendientes).go();
  });
  tearDown(() => base.close());

  Future<List<String>> cola(String tabla) async => [
    for (final f in await base.select(base.colaPendientes).get())
      if (f.tabla == tabla) '${f.operacion}:${f.registroId}',
  ];

  Future<EntradaMercancia> entrada(
    String id,
    DateTime fecha, {
    String cantidad = '24',
    String? factura = 'FV-1',
    Tienda? t,
  }) async {
    final e = EntradaMercancia(
      id,
      itemHuevo,
      d(cantidad),
      fecha,
      d('400'),
      factura,
    );
    await movimientos.guardar(t ?? tienda, e);
    return e;
  }

  ConflictoSincronizacion conflicto(String id) => ConflictoSincronizacion(
    id,
    TipoConflicto.posibleDuplicado,
    'Dos entradas iguales',
    ['a', 'b'],
    f1,
  );

  group('IConflictoRepositorio.guardar', () {
    test('devuelve verdadero si lo inserta y falso si ya existía', () async {
      expect(await conflictos.guardar(tienda, conflicto('c1')), isTrue);
      expect(await conflictos.guardar(tienda, conflicto('c1')), isFalse);
      expect(await cola('conflictos_sincronizacion'), ['INSERTAR:c1']);
    });

    test('falso también si ya estaba resuelto', () async {
      final c = conflicto('c1');
      await conflictos.guardar(tienda, c);
      c.setResuelto(true);
      await conflictos.marcarResuelto(tienda, c);

      expect(await conflictos.guardar(tienda, conflicto('c1')), isFalse);
    });
  });

  group('IMovimientoInventarioRepositorio.listarPorTienda', () {
    test('trae los cuatro tipos y los tres estados en el periodo, del más '
        'antiguo al más reciente, con su ítem y su producto', () async {
      await entrada('e1', f2);
      await entrada('e2', f1);
      await movimientos.guardar(
        tienda,
        Merma('m1', itemHuevo, -d('2'), f1, MotivoMerma.vencido),
      );
      await movimientos.guardar(
        tienda,
        AjusteConteo('a1', itemHuevo, -d('1'), f2, d('45')),
      );
      final venta = Venta(
        'v1',
        [PagoContado('pc1', d('550'), Decimal.zero)],
        d('550'),
        f1,
      );
      await ventas.guardar(tienda, venta);
      await movimientos.guardar(
        tienda,
        SalidaVenta('s1', itemHuevo, -d('1'), f1, venta, d('550'), d('400')),
      );
      final enRevision = (await movimientos.buscarPorIds(tienda, ['e1'])).single
        ..setEstado(EstadoMovimiento.enRevision);
      await movimientos.actualizarEstado(tienda, enRevision);

      final lista = await movimientos.listarPorTienda(tienda, desde, ahora);

      expect(lista.map((m) => m.getId()), ['e2', 'm1', 's1', 'a1', 'e1']);
      expect(lista.first, isA<EntradaMercancia>());
      expect(lista[1], isA<Merma>());
      expect(lista[2], isA<SalidaVenta>());
      expect(lista[3], isA<AjusteConteo>());
      expect(lista.last.getEstado(), EstadoMovimiento.enRevision);
      expect(lista.first.getItem().getProducto().getNombre(), 'Huevo AA');
      expect(identical(lista[0].getItem(), lista[1].getItem()), isTrue);
    });

    test(
      'el periodo es [desde, hasta): incluye el inicio y no el final',
      () async {
        await entrada('e1', desde);
        await entrada('e2', ahora);
        await entrada('e3', desde.subtract(const Duration(seconds: 1)));

        final lista = await movimientos.listarPorTienda(tienda, desde, ahora);

        expect(lista.map((m) => m.getId()), ['e1']);
      },
    );

    test('no trae movimientos de otra tienda', () async {
      await entrada('e1', f1);
      await entrada('e2', f1, t: otra);

      expect(
        (await movimientos.listarPorTienda(
          tienda,
          desde,
          ahora,
        )).map((m) => m.getId()),
        ['e1'],
      );
    });
  });

  group('IFiadoRepositorio.listarModificadosDesde', () {
    Future<Fiado> fiado(
      String id,
      DateTime inicio, {
      List<DateTime> abonos = const [],
      Tienda? t,
    }) async {
      final tt = t ?? tienda;
      final cliente = Cliente('c-$id', 'Cliente $id', '');
      await clientes.guardar(tt, cliente);
      final f = Fiado(id, d('10000'), inicio, cliente);
      await ventas.guardar(tt, Venta('v-$id', [f], d('10000'), inicio));
      await fiados.crear(tt, f);
      for (final (i, fecha) in abonos.indexed) {
        final a = Abono('$id-a$i', d('1000'), fecha, MedioPago.efectivo, null);
        f.registrarAbono(a);
        await fiados.registrarAbono(tt, f, a);
      }
      return f;
    }

    test('trae los que empezaron o recibieron un abono desde la fecha, con '
        'su cliente y todos sus abonos', () async {
      final viejo = desde.subtract(const Duration(days: 3));
      await fiado('nuevo', f1);
      await fiado('conAbonoNuevo', viejo, abonos: [viejo, f2]);
      await fiado('sinCambios', viejo, abonos: [viejo]);

      final lista = await fiados.listarModificadosDesde(tienda, desde);

      expect(lista.map((f) => f.getId()), ['conAbonoNuevo', 'nuevo']);
      final conAbono = lista.first;
      expect(conAbono.getCliente().getNombre(), 'Cliente conAbonoNuevo');
      expect(conAbono.getAbonos().map((a) => a.getId()), [
        'conAbonoNuevo-a0',
        'conAbonoNuevo-a1',
      ]);
    });

    test('cuenta el abono anulado y no trae fiados de otra tienda', () async {
      final viejo = desde.subtract(const Duration(days: 3));
      final f = await fiado('f1', viejo, abonos: [f1]);
      await fiados.anularAbono(tienda, f, f.getAbonos().single);
      await fiado('f2', f1, t: otra);

      final lista = await fiados.listarModificadosDesde(tienda, desde);

      expect(lista.map((x) => x.getId()), ['f1']);
    });

    test('sin fiados devuelve una lista vacía', () async {
      expect(await fiados.listarModificadosDesde(tienda, desde), isEmpty);
    });
  });

  group('conciliar de punta a punta', () {
    /// Un fiado de 10.000 al que dos equipos le sumaron 8.000 cada uno.
    Future<void> fiadoConAbonoDeMas() async {
      final cliente = Cliente('c1', 'María Pérez', '');
      await clientes.guardar(tienda, cliente);
      final fiado = Fiado('f1', d('10000'), f1, cliente);
      await ventas.guardar(tienda, Venta('v-f1', [fiado], d('10000'), f1));
      await fiados.crear(tienda, fiado);
      final a1 = Abono('a1', d('8000'), f1, MedioPago.efectivo, null);
      fiado.registrarAbono(a1);
      await fiados.registrarAbono(tienda, fiado, a1);
      final a2 = Abono('a2', d('8000'), f2, MedioPago.efectivo, null);
      await fiados.registrarAbono(
        tienda,
        Fiado.guardado(
          'f1',
          d('10000'),
          f1,
          cliente,
          d('2000'),
          EstadoFiado.pendiente,
          [a1, a2],
        ),
        a2,
      );
    }

    Future<void> cajaConMovimientoTarde() async {
      final dia = DateTime(2026, 11, 19);
      final idCaja = ServicioCaja.idCaja(tienda, dia);
      await cajas.crear(tienda, Caja(idCaja, dia));
      await cajas.cerrar(
        tienda,
        Caja(
          idCaja,
          dia,
          efectivoContado: d('10000'),
          diferencia: d('0'),
          fechaCierre: DateTime(2026, 11, 19, 18).toUtc(),
        ),
      );
      await cajas.registrarMovimiento(
        tienda,
        Caja(idCaja, dia),
        MovimientoCaja(
          'mc1',
          d('5000'),
          'Pago de la luz',
          ClasificacionMovimiento.negocio,
          TipoMovimientoCaja.egreso,
          DateTime(2026, 11, 19, 19).toUtc(),
        ),
      );
    }

    Future<void> sembrarLosCincoChoques() async {
      await entrada('e1', f1);
      await entrada('e2', f2);
      await movimientos.guardar(
        tienda,
        EntradaMercancia('e3', itemHuevo, d('-60'), f2, d('0'), null),
      );
      await fiadoConAbonoDeMas();
      await productos.guardar(
        tienda,
        Producto('p2', 'H1', 'Huevo AAA', UnidadMedida.unidad, d('1'), d('2'))
          ..agregarCodigo(CodigoProducto('k2', FormatoCodigo.ean13, '770')),
      );
      await productos.guardar(
        tienda,
        Producto('p3', 'X9', 'Otro', UnidadMedida.unidad, d('1'), d('2'))
          ..agregarCodigo(CodigoProducto('k3', FormatoCodigo.ean13, '770')),
      );
      await cajaConMovimientoTarde();
      await base.delete(base.colaPendientes).go();
    }

    test(
      'detecta, guarda y anota en la cola los cinco tipos de choque',
      () async {
        await sembrarLosCincoChoques();

        final nuevos = await servicio().conciliar(tienda, desde);

        expect(nuevos.map((c) => c.getTipo()).toSet(), {
          TipoConflicto.posibleDuplicado,
          TipoConflicto.stockNegativo,
          TipoConflicto.abonoExcedeSaldo,
          TipoConflicto.codigoRepetido,
          TipoConflicto.movimientoCajaCerrada,
        });
        final guardados = await conflictos.listarPendientes(tienda);
        expect(guardados.map((c) => c.getId()).toSet(), {
          for (final c in nuevos) c.getId(),
        });
        expect(
          guardados
              .firstWhere((c) => c.getTipo() == TipoConflicto.abonoExcedeSaldo)
              .getIdsRegistros(),
          ['f1', 'a1', 'a2'],
        );
        // La cola lleva cada conflicto, el estado de la entrada y el saldo
        // corregido del fiado.
        expect((await cola('conflictos_sincronizacion')).length, nuevos.length);
        expect(await cola('movimientos_inventario'), ['ACTUALIZAR:e2']);
        expect(await cola('fiados'), ['ACTUALIZAR:f1']);
      },
    );

    test('la segunda entrada queda EN_REVISION y el stock se recalcula sin '
        'ella', () async {
      await sembrarLosCincoChoques();

      await servicio().conciliar(tienda, desde);

      final e2 = (await movimientos.buscarPorIds(tienda, ['e2'])).single;
      expect(e2.getEstado(), EstadoMovimiento.enRevision);
      // 24 (e1) - 60 (e3); e2 en revisión no suma.
      expect(
        (await items.buscarItem(tienda, huevo))!.getStockActual(),
        d('-36'),
      );
    });

    test('el fiado queda con el saldo recalculado', () async {
      await sembrarLosCincoChoques();

      await servicio().conciliar(tienda, desde);

      final fiado = (await fiados.buscarPorId(tienda, 'f1'))!;
      expect(fiado.getSaldoPendiente(), d('-6000'));
    });

    test('repetir la conciliación no crea ni escribe nada más', () async {
      await sembrarLosCincoChoques();
      await servicio().conciliar(tienda, desde);
      final colaAntes = (await base.select(base.colaPendientes).get()).length;

      final otraVez = await servicio().conciliar(tienda, desde);

      expect(otraVez, isEmpty);
      expect((await base.select(base.colaPendientes).get()).length, colaAntes);
    });

    test('si algo falla se deshace todo: conflictos, estado y saldo', () async {
      await sembrarLosCincoChoques();

      await expectLater(
        servicio(_ConflictosQueFallanAlTercero(conflictos))
            .conciliar(tienda, desde),
        throwsA(isA<StateError>()),
      );

      expect(await conflictos.listarPendientes(tienda), isEmpty);
      final e2 = (await movimientos.buscarPorIds(tienda, ['e2'])).single;
      expect(e2.getEstado(), EstadoMovimiento.vigente);
      expect(
        (await fiados.buscarPorId(tienda, 'f1'))!.getSaldoPendiente(),
        d('2000'),
      );
      expect(await base.select(base.colaPendientes).get(), isEmpty);
    });
  });
}

/// Falla al guardar el tercer conflicto, después de haber guardado y marcado
/// otros: sirve para probar que el rollback deshace todo.
class _ConflictosQueFallanAlTercero implements IConflictoRepositorio {
  _ConflictosQueFallanAlTercero(this._real);

  final IConflictoRepositorio _real;
  var _llamadas = 0;

  @override
  Future<bool> guardar(Tienda tienda, ConflictoSincronizacion conflicto) async {
    if (++_llamadas == 3) throw StateError('falla del disco');
    return _real.guardar(tienda, conflicto);
  }

  @override
  Future<List<ConflictoSincronizacion>> listarPendientes(Tienda tienda) =>
      _real.listarPendientes(tienda);

  @override
  Future<void> marcarResuelto(
    Tienda tienda,
    ConflictoSincronizacion conflicto,
  ) => _real.marcarResuelto(tienda, conflicto);
}
