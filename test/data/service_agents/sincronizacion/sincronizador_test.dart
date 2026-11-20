import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show OrderingTerm, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_movimientos.dart';
import 'package:gip/business/componentes/info_tienda/servicio_conciliacion.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/workflow/info_tienda/conciliar_coordinator.dart';
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
import 'package:gip/data/service_agents/sincronizacion/sincronizador.dart';

import 'servidor_remoto_falso.dart';

/// El Sincronizador (CUS-23, DI-47) con dos "equipos" (cada uno con su base
/// local) y un servidor en memoria que aplica las mismas reglas que
/// `20261121090000_sincronizacion.sql`. Lo que NO prueba: las llamadas reales a
/// Supabase ni el SQL de la migración.
void main() {
  // Dos equipos = dos bases en memoria distintas, a propósito.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otra = Tienda('t2', 'T002', 'Otra tienda', 'Turbaco');
  Decimal d(String v) => Decimal.parse(v);

  final f1 = DateTime.utc(2026, 11, 19, 15);
  final f2 = DateTime.utc(2026, 11, 19, 16);
  final ahora = DateTime.utc(2026, 11, 19, 20);

  late ServidorRemotoFalso servidor;
  late _Equipo a;
  late _Equipo b;

  setUp(() {
    servidor = ServidorRemotoFalso();
    a = _Equipo(servidor, ahora);
    b = _Equipo(servidor, ahora);
  });
  tearDown(() async {
    await a.cerrar();
    await b.cerrar();
  });

  Future<Producto> huevo(
    _Equipo e, {
    Tienda? t,
    String nombre = 'Huevo AA',
  }) async {
    final p = Producto(
      'p-huevo',
      'H1',
      nombre,
      UnidadMedida.unidad,
      d('400'),
      d('550'),
    )..setActualizadoEn(DateTime.utc(2026, 11, 18));
    await e.productos.guardar(t ?? tienda, p);
    await e.items.guardarItem(
      t ?? tienda,
      ItemInventario('i-huevo', p, d('0')),
    );
    return p;
  }

  Future<ItemInventario> itemHuevo(_Equipo e, {Tienda? t}) async =>
      (await e.items.listarItems(t ?? tienda)).single;

  Future<EntradaMercancia> entrada(
    _Equipo e,
    String id, {
    String cantidad = '24',
    String? factura = 'FV-1',
    DateTime? fecha,
  }) async {
    final m = EntradaMercancia(
      id,
      await itemHuevo(e),
      d(cantidad),
      fecha ?? f1,
      d('400'),
      factura,
    );
    await e.movimientos.guardar(tienda, m);
    return m;
  }

  group('subir', () {
    test(
      'sube lo que hay en la cola con el formato del servidor y la vacía',
      () async {
        await huevo(a);
        await entrada(a, 'e1');

        final r = await a.sincronizador.sincronizar(tienda);

        expect(r.termino, isTrue);
        expect(r.pendientes, 0);
        expect(await a.cola(), isEmpty);
        expect(servidor.cuantas('productos'), 1);
        expect(servidor.cuantas('items_inventario'), 1);
        final p = servidor.fila('productos', 'p-huevo')!;
        expect(p['nombre'], 'Huevo AA');
        expect(p['precio_venta'], 550); // numeric, no texto
        expect(p['tienda_id'], 't1');
        final e = servidor.fila('movimientos_inventario', 'e1')!;
        expect(e['tipo'], 'ENTRADA');
        expect(e['cantidad'], 24);
        expect(e['estado'], 'VIGENTE');
        expect(e['numero_factura'], 'FV-1');
        expect(e['fecha'], '2026-11-19T15:00:00.000+00:00');
        // El stock no viaja (DI-17).
        expect(
          servidor
              .fila('items_inventario', 'i-huevo')!
              .containsKey('stock_actual'),
          isFalse,
        );
      },
    );

    test('sube cada tabla en lotes y los padres antes que los hijos', () async {
      await huevo(a);
      for (var i = 0; i < 5; i++) {
        await entrada(a, 'e$i', cantidad: '${i + 1}', factura: 'F$i');
      }
      a.sincronizador = a.crearSincronizador(servidor, ahora, tamanoLote: 2);

      await a.sincronizador.sincronizar(tienda);

      final subidas = [
        for (final p in servidor.peticiones)
          if (p.startsWith('insertar') || p.startsWith('guardar')) p,
      ];
      expect(subidas, [
        'insertar productos 1',
        'insertar items_inventario 1',
        'insertar movimientos_inventario 2',
        'insertar movimientos_inventario 2',
        'insertar movimientos_inventario 1',
      ]);
      expect(servidor.cuantas('movimientos_inventario'), 5);
    });

    test('varias entradas del mismo registro suben una sola vez, con su estado '
        'de ahora', () async {
      final p = await huevo(a);
      p.setNombre('Huevo AAA');
      p.setActualizadoEn(f2);
      await a.productos.guardar(tienda, p);

      await a.sincronizador.sincronizar(tienda);

      expect(servidor.fila('productos', 'p-huevo')!['nombre'], 'Huevo AAA');
      expect(
        servidor.peticiones.where((x) => x == 'guardar productos 1'),
        hasLength(1),
      );
      expect(
        servidor.peticiones.where((x) => x.startsWith('insertar productos')),
        isEmpty,
      );
    });

    test('sin conexión no pierde nada y no se queda a medias', () async {
      await huevo(a);
      servidor.sinRed = true;

      final r = await a.sincronizador.sincronizar(tienda);

      expect(r.sinConexion, isTrue);
      expect(r.subidos, 0);
      expect(r.pendientes, greaterThan(0));
      expect(await a.cola(), isNotEmpty);

      servidor.sinRed = false;
      final despues = await a.sincronizador.sincronizar(tienda);

      expect(despues.termino, isTrue);
      expect(despues.pendientes, 0);
      expect(servidor.cuantas('productos'), 1);
    });

    test('una fila que el servidor rechaza queda en la cola con un intento y '
        'no frena a las demás', () async {
      await huevo(a);
      await entrada(a, 'e1', factura: 'F1');
      await entrada(a, 'e2', factura: 'F2');
      servidor.rechazar.add('e1');

      final r = await a.sincronizador.sincronizar(tienda);

      expect(servidor.fila('movimientos_inventario', 'e1'), isNull);
      expect(servidor.fila('movimientos_inventario', 'e2'), isNotNull);
      expect(r.pendientes, 1);
      final cola = await a.cola();
      expect(cola.single, 'movimientos_inventario:e1');
      expect(
        (await a.base.select(a.base.colaPendientes).get()).single.intentos,
        1,
      );

      servidor.rechazar.clear();
      await a.sincronizador.sincronizar(tienda);

      expect(servidor.fila('movimientos_inventario', 'e1'), isNotNull);
      expect(await a.cola(), isEmpty);
    });

    test('descarta las entradas de las alertas y los cambios de stock: no se '
        'sincronizan', () async {
      await huevo(a);
      await a.base.customStatement(
        "INSERT INTO cola_pendientes (id, tienda_id, tabla, registro_id, "
        "operacion, intentos, creado_en) VALUES ('c1', 't1', "
        "'alertas_reabastecimiento', 'x', 'INSERTAR', 0, '2026-11-19T10:00:00.000Z')",
      );
      await a.items.guardarItem(
        tienda,
        ItemInventario('i-huevo', (await itemHuevo(a)).getProducto(), d('99')),
      );

      await a.sincronizador.sincronizar(tienda);

      expect(servidor.cuantas('alertas_reabastecimiento'), 0);
      expect(await a.cola(), isEmpty);
      expect(
        servidor.peticiones
            .where(
              (p) => p.endsWith('items_inventario 1') && !p.startsWith('leer'),
            )
            .length,
        1, // solo el INSERT del ítem
      );
    });

    test('una fila que ya no existe se saca de la cola sin enviarla', () async {
      await huevo(a);
      await a.base.customStatement(
        "DELETE FROM productos WHERE id = 'p-huevo'",
      );

      await a.sincronizador.sincronizar(tienda);

      expect(servidor.cuantas('productos'), 0);
      expect(await a.cola(), isEmpty);
    });

    test('solo sube lo de la tienda de la sesión', () async {
      await huevo(a);
      await a.productos.guardar(
        otra,
        Producto('p-otro', 'X', 'Otro', UnidadMedida.unidad, d('1'), d('2')),
      );

      await a.sincronizador.sincronizar(tienda);

      expect(servidor.fila('productos', 'p-huevo'), isNotNull);
      expect(servidor.fila('productos', 'p-otro'), isNull);
      expect((await a.cola()).single, 'productos:p-otro');
    });
  });

  group('bajar', () {
    test('un equipo recibe lo que subió el otro y no lo vuelve a poner en su '
        'cola', () async {
      await huevo(a);
      await entrada(a, 'e1');
      await a.sincronizador.sincronizar(tienda);

      final r = await b.sincronizador.sincronizar(tienda);

      expect(r.bajados, greaterThan(0));
      expect(await b.cola(), isEmpty);
      final p = (await b.productos.buscarPorId(tienda, 'p-huevo'))!;
      expect(p.getNombre(), 'Huevo AA');
      expect(p.getPrecioVenta(), d('550'));
      final e = (await b.movimientos.buscarPorIds(tienda, ['e1'])).single;
      expect(e.getCantidad(), d('24'));
      expect(e.getFecha(), f1);
      expect((e as EntradaMercancia).getNumeroFactura(), 'FV-1');
    });

    test(
      'el stock del ítem se recalcula con los movimientos que llegaron',
      () async {
        await huevo(a);
        await entrada(a, 'e1', cantidad: '24');
        await entrada(a, 'e2', cantidad: '6', factura: 'FV-2');
        await a.sincronizador.sincronizar(tienda);

        await b.sincronizador.sincronizar(tienda);

        expect((await itemHuevo(b)).getStockActual(), d('30'));
      },
    );

    test('con el cursor al día no baja ni concilia nada otra vez', () async {
      await huevo(a);
      await entrada(a, 'e1');
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      b.conciliaciones.clear();

      final r = await b.sincronizador.sincronizar(tienda);

      expect(r.bajados, 0);
      expect(r.subidos, 0);
      expect(b.conciliaciones, isEmpty);
      expect(await b.cola(), isEmpty);
    });

    test('baja por páginas hasta traer todo', () async {
      await huevo(a);
      for (var i = 0; i < 7; i++) {
        await entrada(a, 'e$i', cantidad: '${i + 1}', factura: 'F$i');
      }
      await a.sincronizador.sincronizar(tienda);
      b.sincronizador = b.crearSincronizador(servidor, ahora, tamanoPagina: 2);

      await b.sincronizador.sincronizar(tienda);

      expect(
        (await b.movimientos.listarPorTienda(
          tienda,
          DateTime.utc(2000),
          DateTime.utc(3000),
        )).length,
        7,
      );
    });

    test('solo baja la tienda de la sesión', () async {
      await huevo(a);
      await a.productos.guardar(
        otra,
        Producto('p-otro', 'X', 'Otro', UnidadMedida.unidad, d('1'), d('2')),
      );
      await a.sincronizador.sincronizar(tienda);
      await a.sincronizador.sincronizar(otra);

      await b.sincronizador.sincronizar(tienda);

      expect(await b.productos.buscarPorId(tienda, 'p-huevo'), isNotNull);
      expect(await b.productos.buscarPorId(otra, 'p-otro'), isNull);
    });

    test('no pisa lo que está pendiente de subir', () async {
      final p = await huevo(a);
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      // A cambia el nombre más tarde y lo sube.
      p.setNombre('Huevo AAA');
      p.setActualizadoEn(f2);
      await a.productos.guardar(tienda, p);
      await a.sincronizador.sincronizar(tienda);
      // B también lo cambia, aún más tarde, pero el servidor rechaza su subida.
      final pb = (await b.productos.buscarPorId(tienda, 'p-huevo'))!;
      pb.setNombre('Huevo B');
      pb.setActualizadoEn(f2.add(const Duration(hours: 1)));
      await b.productos.guardar(tienda, pb);
      servidor.rechazar.add('p-huevo');

      await b.sincronizador.sincronizar(tienda);

      expect(
        (await b.productos.buscarPorId(tienda, 'p-huevo'))!.getNombre(),
        'Huevo B',
      );
      expect(await b.cola(), contains('productos:p-huevo'));
    });
  });

  group('reglas de choque', () {
    test('en productos gana la edición más reciente, sin importar quién '
        'sincroniza primero', () async {
      final pa = await huevo(a);
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      final pb = (await b.productos.buscarPorId(tienda, 'p-huevo'))!;
      pb
        ..setNombre('Huevo de B')
        ..setActualizadoEn(f2.add(const Duration(minutes: 5)));
      pa
        ..setNombre('Huevo de A')
        ..setActualizadoEn(f2);
      await a.productos.guardar(tienda, pa);
      await b.productos.guardar(tienda, pb);

      // B (la más reciente) sube primero; A, más vieja, sube después.
      await b.sincronizador.sincronizar(tienda);
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);

      expect(servidor.fila('productos', 'p-huevo')!['nombre'], 'Huevo de B');
      for (final e in [a, b]) {
        expect(
          (await e.productos.buscarPorId(tienda, 'p-huevo'))!.getNombre(),
          'Huevo de B',
        );
      }
    });

    test('un movimiento anulado no se revierte', () async {
      await huevo(a);
      final m = await entrada(a, 'e1');
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      // A lo anula; B (sin saberlo) lo deja vigente y lo vuelve a subir.
      m.setEstado(EstadoMovimiento.anulado);
      await a.movimientos.actualizarEstado(tienda, m);
      final mb = (await b.movimientos.buscarPorIds(tienda, ['e1'])).single
        ..setEstado(EstadoMovimiento.enRevision);
      await b.movimientos.actualizarEstado(tienda, mb);

      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      await a.sincronizador.sincronizar(tienda);

      expect(
        servidor.fila('movimientos_inventario', 'e1')!['estado'],
        'ANULADO',
      );
      for (final e in [a, b]) {
        expect(
          (await e.movimientos.buscarPorIds(tienda, ['e1'])).single.getEstado(),
          EstadoMovimiento.anulado,
        );
      }
    });

    test('un código quitado en un equipo se quita en el otro', () async {
      final p = await huevo(a);
      final codigo = CodigoProducto('k1', FormatoCodigo.ean13, '7701234567895');
      p.agregarCodigo(codigo);
      await a.productos.guardar(tienda, p);
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      expect(
        (await b.productos.buscarPorId(tienda, 'p-huevo'))!.getCodigos(),
        hasLength(1),
      );

      await a.productos.quitarCodigo(tienda, p, codigo);
      await a.sincronizador.sincronizar(tienda);
      expect(servidor.fila('codigos_producto', 'k1'), isNull);
      await b.sincronizador.sincronizar(tienda);

      expect(
        (await b.productos.buscarPorId(tienda, 'p-huevo'))!.getCodigos(),
        isEmpty,
      );
      expect(await b.cola(), isEmpty);
    });

    test('un abono anulado en un equipo queda anulado en el otro', () async {
      await a.fiadoConAbonos(tienda, abonos: [('a1', '4000', f1)]);
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      final fiado = (await a.fiados.buscarPorId(tienda, 'f1'))!;
      await a.fiados.anularAbono(tienda, fiado, fiado.getAbonos().single);

      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);

      final enB = (await b.fiados.buscarPorId(tienda, 'f1'))!;
      expect(enB.getAbonos().single.isAnulado(), isTrue);
    });
  });

  group('conciliación después de bajar', () {
    test('dos equipos que registran la misma entrada: queda un conflicto con '
        'el mismo id en los dos y las dos entradas suman', () async {
      await huevo(a);
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      // Cada equipo, sin internet, registra la misma entrada de la factura.
      await entrada(a, 'ea', fecha: f1);
      await entrada(b, 'eb', fecha: f2);

      await a.sincronizador.sincronizar(tienda);
      final rb = await b.sincronizador.sincronizar(tienda);
      final ra = await a.sincronizador.sincronizar(tienda);

      expect(rb.conflictosNuevos.map((c) => c.getTipo()), [
        TipoConflicto.posibleDuplicado,
      ]);
      expect(ra.conflictosNuevos, isEmpty); // ya lo creó B y A solo lo baja
      final enA = await a.conflictos.listarPendientes(tienda);
      final enB = await b.conflictos.listarPendientes(tienda);
      expect(enA.map((c) => c.getId()), enB.map((c) => c.getId()));
      expect(enA, hasLength(1));
      for (final e in [a, b]) {
        for (final id in ['ea', 'eb']) {
          expect(
            (await e.movimientos.buscarPorIds(tienda, [id])).single.getEstado(),
            EstadoMovimiento.vigente,
          );
        }
      }
      expect(
        servidor.fila('movimientos_inventario', 'eb')!['estado'],
        'VIGENTE',
      );
      expect(servidor.cuantas('conflictos_sincronizacion'), 1);
      // Hasta que el propietario decida, el stock de los dos equipos cuenta
      // las dos entradas (DI-50).
      expect((await itemHuevo(a)).getStockActual(), d('48'));
      expect((await itemHuevo(b)).getStockActual(), d('48'));
    });

    test('dos equipos que abonan de más al mismo fiado: conflicto de abono '
        'y saldo negativo en los dos', () async {
      await a.fiadoConAbonos(tienda, abonos: [('a1', '8000', f1)]);
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      final fa = (await a.fiados.buscarPorId(tienda, 'f1'))!;
      await a.agregarAbono(
        tienda,
        fa,
        Abono('a-a', d('2000'), f1, MedioPago.efectivo, null),
      );
      final fb = (await b.fiados.buscarPorId(tienda, 'f1'))!;
      await b.agregarAbono(
        tienda,
        fb,
        Abono('a-b', d('2000'), f2, MedioPago.efectivo, null),
      );
      // 8.000 + 2.000 + 2.000 = 12.000 sobre un fiado de 10.000.

      await a.sincronizador.sincronizar(tienda);
      final rb = await b.sincronizador.sincronizar(tienda);
      await a.sincronizador.sincronizar(tienda);

      expect(
        rb.conflictosNuevos.single.getTipo(),
        TipoConflicto.abonoExcedeSaldo,
      );
      for (final e in [a, b]) {
        final f = (await e.fiados.buscarPorId(tienda, 'f1'))!;
        expect(f.getAbonos(), hasLength(3));
        expect(f.getSaldoPendiente(), d('-2000'));
        expect(await e.conflictos.listarPendientes(tienda), hasLength(1));
      }
      expect(servidor.fila('fiados', 'f1')!['saldo_pendiente'], -2000);
    });

    test('un conflicto que el propietario resuelve en un equipo se resuelve en '
        'el otro', () async {
      await huevo(a);
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      await entrada(a, 'ea', fecha: f1);
      await entrada(b, 'eb', fecha: f2);
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      await a.sincronizador.sincronizar(tienda);
      final enB = (await b.conflictos.listarPendientes(tienda)).single;
      expect(await a.conflictos.listarPendientes(tienda), hasLength(1));

      enB.setResuelto(true);
      await b.conflictos.marcarResuelto(tienda, enB);
      await b.sincronizador.sincronizar(tienda);
      await a.sincronizador.sincronizar(tienda);

      expect(await a.conflictos.listarPendientes(tienda), isEmpty);
      expect(await b.conflictos.listarPendientes(tienda), isEmpty);
      expect(
        servidor.fila('conflictos_sincronizacion', enB.getId())!['resuelto'],
        true,
      );
    });

    test('si la conciliación falla, lo subido y lo bajado se conserva y el '
        'resultado lo dice', () async {
      await huevo(a);
      await entrada(a, 'e1');
      await a.sincronizador.sincronizar(tienda);
      b.falla = true;

      final r = await b.sincronizador.sincronizar(tienda);

      expect(r.error, contains('No se pudo conciliar'));
      expect(r.bajados, greaterThan(0));
      expect(await b.movimientos.buscarPorIds(tienda, ['e1']), hasLength(1));
    });

    test(
      'la conciliación recibe la fecha del registro más antiguo que llegó',
      () async {
        await huevo(a);
        await entrada(a, 'e1', fecha: f2);
        await entrada(a, 'e2', fecha: f1, factura: 'F2');
        await a.sincronizador.sincronizar(tienda);

        await b.sincronizador.sincronizar(tienda);

        expect(b.conciliaciones.single, f1);
      },
    );

    test(
      'lo que escribe la conciliación se sube en la misma sincronización',
      () async {
        await huevo(a);
        await a.sincronizador.sincronizar(tienda);
        await b.sincronizador.sincronizar(tienda);
        await entrada(a, 'ea', fecha: f1);
        await entrada(b, 'eb', fecha: f2);
        await a.sincronizador.sincronizar(tienda);

        final r = await b.sincronizador.sincronizar(tienda);

        expect(r.conflictosNuevos, hasLength(1));
        expect(r.pendientes, 0);
        expect(servidor.cuantas('conflictos_sincronizacion'), 1);
      },
    );
  });

  group('resolver duplicados y el stock', () {
    test('un duplicado entre dos equipos: las dos entradas suman y al anular '
        'una el stock baja en los dos', () async {
      await huevo(a);
      await entrada(a, 'previa', cantidad: '31', factura: 'FV-0', fecha: f1);
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      expect((await itemHuevo(b)).getStockActual(), d('31'));
      // Cada equipo, sin internet, registra la misma entrada de la factura.
      await a.inventarioAplicar(
        tienda,
        'ea',
        d('24'),
        f1.add(const Duration(minutes: 5)),
      );
      await b.inventarioAplicar(
        tienda,
        'eb',
        d('24'),
        f1.add(const Duration(minutes: 6)),
      );
      expect((await itemHuevo(a)).getStockActual(), d('24'));

      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      await a.sincronizador.sincronizar(tienda);

      // Las dos entradas suman mientras el propietario no decide.
      expect((await itemHuevo(a)).getStockActual(), d('79'));
      expect((await itemHuevo(b)).getStockActual(), d('79'));
      final conflicto = (await a.conflictos.listarPendientes(tienda)).single;

      // Acepta una y descarta la otra: el stock baja de 79 a 55.
      await a.servicioConciliacion.resolverConflicto(tienda, conflicto, ['eb']);
      expect((await itemHuevo(a)).getStockActual(), d('55'));
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);

      expect((await itemHuevo(b)).getStockActual(), d('55'));
      expect(await b.conflictos.listarPendientes(tienda), isEmpty);
    });

    test('tres entradas con la misma factura: dos conflictos; al resolverlos '
        'el stock de los dos equipos baja al anular las repetidas', () async {
      await huevo(a);
      await entrada(a, 'e0', fecha: f1);
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      // Cada equipo, sin internet, registra otra entrada con la misma factura.
      await a.inventarioAplicar(
        tienda,
        'ea',
        d('24'),
        f1.add(const Duration(minutes: 55)),
      );
      await b.inventarioAplicar(
        tienda,
        'eb',
        d('24'),
        f1.add(const Duration(minutes: 56)),
      );
      expect((await itemHuevo(a)).getStockActual(), d('24'));

      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);
      await a.sincronizador.sincronizar(tienda);

      final pendientes = await a.conflictos.listarPendientes(tienda);
      expect(pendientes, hasLength(2));
      // Hasta que se decide, las tres entradas suman en los dos equipos.
      expect((await itemHuevo(a)).getStockActual(), d('72'));
      expect((await itemHuevo(b)).getStockActual(), d('72'));

      // El propietario marca el original en los dos y anula los otros.
      for (final c in pendientes) {
        final duplicada = c.getIdsRegistros().firstWhere((id) => id != 'e0');
        await a.servicioConciliacion.resolverConflicto(tienda, c, [duplicada]);
      }
      expect((await itemHuevo(a)).getStockActual(), d('24'));
      await a.sincronizador.sincronizar(tienda);
      await b.sincronizador.sincronizar(tienda);

      for (final e in [a, b]) {
        expect((await itemHuevo(e)).getStockActual(), d('24'));
        for (final id in ['ea', 'eb']) {
          expect(
            (await e.movimientos.buscarPorIds(tienda, [id])).single.getEstado(),
            EstadoMovimiento.anulado,
          );
        }
        expect(await e.conflictos.listarPendientes(tienda), isEmpty);
      }
    });
  });

  group('al instante (DI-48)', () {
    test('lo que se pide mientras corre una sincronización se recoge en otra '
        'vuelta al terminar', () async {
      await huevo(a);
      final puerta = servidor.puerta = Completer<void>();
      final r1 = a.sincronizador.sincronizar(tienda);
      await pumpEventQueue();
      // La primera ya subió y está leyendo; ahora el equipo escribe algo.
      await entrada(a, 'tarde');

      final r2 = a.sincronizador.sincronizar(tienda);
      puerta.complete();
      await r1;

      expect(identical(r1, r2), isTrue);
      expect(servidor.fila('movimientos_inventario', 'tarde'), isNotNull);
      expect(await a.cola(), isEmpty);
    });

    test('no se encierra: como máximo tres vueltas por pedido', () async {
      await huevo(a);
      final r = await a.sincronizador.sincronizar(tienda);

      expect(r.termino, isTrue);
      // Sin pedidos nuevos, una sola vuelta: una lectura por tabla.
      expect(servidor.peticiones.where((p) => p == 'leer productos').length, 1);
    });

    test('escrituras avisa cada vez que se anota algo para subir, y no '
        'cuando la sincronización vacía la cola', () async {
      final avisos = <int>[];
      final suscripcion = a.sincronizador.escrituras.listen(
        (_) => avisos.add(1),
      );
      await huevo(a);
      await pumpEventQueue();
      final tras = avisos.length;
      expect(tras, greaterThan(0));

      await a.sincronizador.sincronizar(tienda);
      await pumpEventQueue();

      expect(
        avisos.length,
        tras,
        reason: 'sacar de la cola no es una escritura',
      );
      await suscripcion.cancel();
    });
  });

  test('dos llamadas a la vez comparten la misma sincronización', () async {
    await huevo(a);

    final r1 = a.sincronizador.sincronizar(tienda);
    final r2 = a.sincronizador.sincronizar(tienda);

    expect(identical(r1, r2), isTrue);
    await r1;
    expect(
      servidor.peticiones.where((p) => p == 'insertar productos 1').length,
      1,
    );
  });
}

/// Un equipo: su base local, sus repositorios y su Sincronizador contra el
/// servidor compartido.
class _Equipo {
  _Equipo(ServidorRemotoFalso servidor, DateTime ahora)
    : base = BaseLocalDrift(NativeDatabase.memory()) {
    unidad = UnidadTrabajoDrift(base);
    productos = ProductoRepositorioDrift(base);
    items = InventarioRepositorioDrift(base);
    movimientos = MovimientoInventarioRepositorioDrift(base);
    ventas = VentaRepositorioDrift(base);
    clientes = ClienteRepositorioDrift(base);
    fiados = FiadoRepositorioDrift(base);
    cajas = CajaRepositorioDrift(base);
    conflictos = ConflictoRepositorioDrift(base);
    sincronizador = crearSincronizador(servidor, ahora);
  }

  final BaseLocalDrift base;
  late final UnidadTrabajoDrift unidad;
  late final ProductoRepositorioDrift productos;
  late final InventarioRepositorioDrift items;
  late final MovimientoInventarioRepositorioDrift movimientos;
  late final VentaRepositorioDrift ventas;
  late final ClienteRepositorioDrift clientes;
  late final FiadoRepositorioDrift fiados;
  late final CajaRepositorioDrift cajas;
  late final ConflictoRepositorioDrift conflictos;
  late Sincronizador sincronizador;
  late ServicioConciliacion servicioConciliacion;

  /// Las fechas `desde` con que se llamó a la conciliación.
  final List<DateTime> conciliaciones = [];

  /// Si es verdadero, la conciliación falla.
  bool falla = false;

  Sincronizador crearSincronizador(
    ServidorRemotoFalso servidor,
    DateTime ahora, {
    int tamanoLote = 100,
    int tamanoPagina = 500,
  }) {
    final inventario = ServicioInventario(
      items,
      movimientos,
      Decimal.fromInt(5),
      unidad,
      productos,
    );
    servicioConciliacion = ServicioConciliacion(
      conflictos,
      movimientos,
      fiados,
      cajas,
      productos,
      inventario,
      unidad,
      [ResolutorMovimientos(movimientos, inventario)],
      reloj: () => ahora,
    );
    final coordinador = ConciliarCoordinator(servicioConciliacion);
    return Sincronizador(
      base,
      servidor,
      (tienda, desde) {
        conciliaciones.add(desde);
        if (falla) throw StateError('falla');
        return coordinador.ejecutar(tienda, desde);
      },
      reloj: () => ahora,
      tamanoLote: tamanoLote,
      tamanoPagina: tamanoPagina,
    );
  }

  /// Entradas de la cola como "tabla:registro", en orden.
  Future<List<String>> cola() async => [
    for (final f in await (base.select(
      base.colaPendientes,
    )..orderBy([(c) => OrderingTerm.asc(c.creadoEn)])).get())
      '${f.tabla}:${f.registroId}',
  ];

  Future<void> cerrar() => base.close();

  /// Una entrada de 24 con la factura FV-1, como la registra la app: el
  /// movimiento y el stock del ítem, juntos.
  Future<void> inventarioAplicar(
    Tienda tienda,
    String id,
    Decimal cantidad,
    DateTime fecha,
  ) async {
    final item = (await items.listarItems(tienda)).single;
    final e = EntradaMercancia(
      id,
      item,
      cantidad,
      fecha,
      Decimal.parse('400'),
      'FV-1',
    );
    await movimientos.guardar(tienda, e);
    item.setStockActual(item.getStockActual() + cantidad);
    await items.guardarItem(tienda, item);
  }

  /// Un fiado de 10.000 de un cliente nuevo, con los abonos dados
  /// (id, monto, fecha). Todo con los repositorios reales.
  Future<void> fiadoConAbonos(
    Tienda tienda, {
    List<(String, String, DateTime)> abonos = const [],
  }) async {
    final d = Decimal.parse;
    final cliente = Cliente('c1', 'María Pérez', '');
    await clientes.guardar(tienda, cliente);
    final fiado = Fiado(
      'f1',
      d('10000'),
      DateTime.utc(2026, 11, 19, 14),
      cliente,
    );
    await ventas.guardar(
      tienda,
      Venta('v-f1', [fiado], d('10000'), DateTime.utc(2026, 11, 19, 14)),
    );
    await fiados.crear(tienda, fiado);
    for (final (id, monto, fecha) in abonos) {
      await agregarAbono(
        tienda,
        fiado,
        Abono(id, d(monto), fecha, MedioPago.efectivo, null),
      );
    }
  }

  Future<void> agregarAbono(Tienda tienda, Fiado fiado, Abono abono) async {
    fiado.registrarAbono(abono);
    await fiados.registrarAbono(tienda, fiado, abono);
  }
}
