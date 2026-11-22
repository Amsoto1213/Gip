import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/info_tienda/servicio_conciliacion.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
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

import '../gestion_caja/fakes_caja.dart';
import '../gestion_inventario/fakes_catalogo.dart';
import '../gestion_inventario/fakes_inventario.dart';
import '../pagos/fakes_pagos.dart';
import 'fakes_conciliacion.dart';

/// conciliar y los detectores (CUS-23, ERS 3.2.1 c, DA-48, DI-46).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otra = Tienda('t2', 'T002', 'Otra tienda', 'Turbaco');
  Decimal d(String v) => Decimal.parse(v);

  final ahora = DateTime.utc(2026, 11, 19, 20);
  final desde = DateTime.utc(2026, 11, 19, 14);
  final hace1h = DateTime.utc(2026, 11, 19, 19);
  final hace2h = DateTime.utc(2026, 11, 19, 18);

  late _Equipo equipo;

  setUp(() => equipo = _Equipo(ahora));

  Future<List<ConflictoSincronizacion>> conciliar([DateTime? d]) =>
      equipo.servicio.conciliar(tienda, d ?? desde);

  group('sin choques', () {
    test('devuelve una lista vacía y no guarda conflictos', () async {
      final nuevos = await conciliar();

      expect(nuevos, isEmpty);
      expect(equipo.conflictos.todos(tienda), isEmpty);
    });

    test('todo ocurre en una sola transacción', () async {
      await equipo.entradas('e1', '10', hace2h, factura: 'F1');
      await equipo.entradas('e2', '10', hace1h, factura: 'F1');
      equipo.movimientos.guardadosEnTransaccion.clear();

      await conciliar();

      expect(equipo.unidad.transacciones, 1);
      expect(equipo.conflictos.guardadosEnTransaccion, everyElement(isTrue));
      expect(equipo.movimientos.guardadosEnTransaccion, everyElement(isTrue));
    });
  });

  group('posible duplicado', () {
    test('dos entradas con el mismo ítem, cantidad y factura: la segunda queda '
        'EN_REVISION y se crea un conflicto', () async {
      final primera = await equipo.entradas('e1', '24', hace2h, factura: 'FV1');
      final segunda = await equipo.entradas('e2', '24', hace1h, factura: 'FV1');

      final nuevos = await conciliar();

      expect(nuevos, hasLength(1));
      final c = nuevos.single;
      expect(c.getTipo(), TipoConflicto.posibleDuplicado);
      expect(c.getIdsRegistros(), ['e1', 'e2']);
      expect(c.getEtiquetasRegistros(), hasLength(2));
      expect(c.getEtiquetasRegistros().first, contains('Entrada de 24'));
      expect(c.getEtiquetasRegistros().first, contains('Huevo AA'));
      expect(c.getEtiquetasRegistros().first, contains('factura FV1'));
      expect(c.getFecha(), ahora);
      expect(c.isResuelto(), isFalse);
      expect(primera.getEstado(), EstadoMovimiento.vigente);
      expect(segunda.getEstado(), EstadoMovimiento.enRevision);
      expect(equipo.movimientos.estadosActualizados, [segunda]);
      expect(equipo.conflictos.todos(tienda), [c]);
    });

    test(
      'la segunda se decide por fecha, no por el orden de llegada',
      () async {
        final reciente = await equipo.entradas(
          'e9',
          '24',
          hace1h,
          factura: 'FV1',
        );
        final antigua = await equipo.entradas(
          'e1',
          '24',
          hace2h,
          factura: 'FV1',
        );

        final nuevos = await conciliar();

        expect(nuevos.single.getIdsRegistros(), ['e1', 'e9']);
        expect(antigua.getEstado(), EstadoMovimiento.vigente);
        expect(reciente.getEstado(), EstadoMovimiento.enRevision);
      },
    );

    test('con tres entradas iguales, una pareja por cada repetida', () async {
      await equipo.entradas('e1', '24', hace2h, factura: 'FV1');
      final b = await equipo.entradas('e2', '24', hace1h, factura: 'FV1');
      final c = await equipo.entradas(
        'e3',
        '24',
        hace1h.add(const Duration(minutes: 5)),
        factura: 'FV1',
      );

      final nuevos = await conciliar();

      expect(nuevos.map((n) => n.getIdsRegistros()), [
        ['e1', 'e2'],
        ['e1', 'e3'],
      ]);
      expect(b.getEstado(), EstadoMovimiento.enRevision);
      expect(c.getEstado(), EstadoMovimiento.enRevision);
    });

    for (final (nombre, preparar) in <(String, Future<void> Function(_Equipo))>[
      (
        'con distinta cantidad',
        (e) async {
          await e.entradas('e1', '24', hace2h, factura: 'FV1');
          await e.entradas('e2', '12', hace1h, factura: 'FV1');
        },
      ),
      (
        'con distinta factura',
        (e) async {
          await e.entradas('e1', '24', hace2h, factura: 'FV1');
          await e.entradas('e2', '24', hace1h, factura: 'FV2');
        },
      ),
      (
        'de otro ítem',
        (e) async {
          await e.entradas('e1', '24', hace2h, factura: 'FV1');
          await e.entradas('e2', '24', hace1h, factura: 'FV1', item: e.cafe);
        },
      ),
      (
        'sin número de factura',
        (e) async {
          await e.entradas('e1', '24', hace2h);
          await e.entradas('e2', '24', hace1h);
        },
      ),
      (
        'con factura en blanco',
        (e) async {
          await e.entradas('e1', '24', hace2h, factura: ' ');
          await e.entradas('e2', '24', hace1h, factura: ' ');
        },
      ),
      (
        'si la otra ya está anulada',
        (e) async {
          await e.entradas('e1', '24', hace2h, factura: 'FV1');
          await e.entradas(
            'e2',
            '24',
            hace1h,
            factura: 'FV1',
            estado: EstadoMovimiento.anulado,
          );
        },
      ),
    ]) {
      test('no es duplicado $nombre', () async {
        await preparar(equipo);

        final nuevos = await conciliar();

        expect(
          nuevos.where((c) => c.getTipo() == TipoConflicto.posibleDuplicado),
          isEmpty,
        );
        expect(equipo.movimientos.estadosActualizados, isEmpty);
      });
    }

    test(
      'las ventas y las pérdidas con la misma cantidad no cuentan',
      () async {
        await equipo.entradas(
          'e0',
          '100',
          desde.subtract(const Duration(days: 3)),
        );
        await equipo.salida('s1', '3', hace2h);
        await equipo.salida('s2', '3', hace1h);

        final nuevos = await conciliar();

        expect(nuevos, isEmpty);
      },
    );

    test('encuentra la pareja si la original es de hasta un día antes del '
        'desde', () async {
      await equipo.entradas(
        'e1',
        '24',
        desde.subtract(const Duration(hours: 20)),
        factura: 'FV1',
      );
      await equipo.entradas('e2', '24', hace1h, factura: 'FV1');

      final nuevos = await conciliar();

      expect(nuevos.single.getIdsRegistros(), ['e1', 'e2']);
    });

    test('no busca la pareja más allá del margen', () async {
      await equipo.entradas(
        'e1',
        '24',
        desde.subtract(const Duration(days: 3)),
        factura: 'FV1',
      );
      await equipo.entradas('e2', '24', hace1h, factura: 'FV1');

      expect(await conciliar(), isEmpty);
    });

    test('repetir la conciliación no crea otro conflicto ni vuelve a tocar el '
        'movimiento', () async {
      await equipo.entradas('e1', '24', hace2h, factura: 'FV1');
      await equipo.entradas('e2', '24', hace1h, factura: 'FV1');
      await conciliar();

      final otraVez = await conciliar();

      expect(otraVez, isEmpty);
      expect(equipo.conflictos.todos(tienda), hasLength(1));
      expect(equipo.movimientos.estadosActualizados, hasLength(1));
    });

    test(
      'si el propietario dijo "son distintas" no se vuelve a poner EN_REVISION '
      'ni se vuelve a avisar',
      () async {
        await equipo.entradas('e1', '24', hace2h, factura: 'FV1');
        final segunda = await equipo.entradas(
          'e2',
          '24',
          hace1h,
          factura: 'FV1',
        );
        final nuevo = (await conciliar()).single;
        // CUS-22: resuelve sin anular nada y la deja VIGENTE.
        nuevo.setResuelto(true);
        segunda.setEstado(EstadoMovimiento.vigente);
        equipo.movimientos.estadosActualizados.clear();

        final otraVez = await conciliar();

        expect(otraVez, isEmpty);
        expect(segunda.getEstado(), EstadoMovimiento.vigente);
        expect(equipo.movimientos.estadosActualizados, isEmpty);
      },
    );

    test('la segunda entrada en revisión no suma al stock', () async {
      await equipo.entradas('e1', '24', hace2h, factura: 'FV1');
      await equipo.entradas('e2', '24', hace1h, factura: 'FV1');

      await conciliar();

      expect(
        equipo.items.datos[tienda.getId()]!['i1']!.getStockActual(),
        d('24'),
      );
    });

    test(
      'dos equipos que detectan el mismo duplicado crean el mismo id',
      () async {
        final otroEquipo = _Equipo(ahora);
        for (final e in [equipo, otroEquipo]) {
          await e.entradas('e1', '24', hace2h, factura: 'FV1');
          await e.entradas('e2', '24', hace1h, factura: 'FV1');
        }

        final a = (await conciliar()).single;
        final b = (await otroEquipo.servicio.conciliar(tienda, desde)).single;

        expect(a.getId(), b.getId());
      },
    );
  });

  group('stock negativo', () {
    test('recalcula el stock y avisa del ítem que queda negativo', () async {
      await equipo.entradas('e1', '10', hace2h);
      await equipo.salida('s1', '16', hace1h);

      final nuevos = await conciliar();

      final c = nuevos.single;
      expect(c.getTipo(), TipoConflicto.stockNegativo);
      expect(c.getDescripcion(), contains('Huevo AA'));
      expect(c.getDescripcion(), contains('-6'));
      expect(c.getIdsRegistros(), ['e1', 's1']);
      expect(c.getEtiquetasRegistros().last, contains('Venta de 16'));
      expect(
        equipo.items.datos[tienda.getId()]!['i1']!.getStockActual(),
        d('-6'),
      );
    });

    test(
      'un ítem con stock positivo se recalcula y no genera conflicto',
      () async {
        await equipo.entradas('e1', '10', hace2h);
        await equipo.salida('s1', '4', hace1h);

        final nuevos = await conciliar();

        expect(nuevos, isEmpty);
        expect(
          equipo.items.datos[tienda.getId()]!['i1']!.getStockActual(),
          d('6'),
        );
      },
    );

    test('el stock guardado se corrige con la suma de los movimientos '
        'vigentes', () async {
      // El ítem guardado dice 999, un número viejo de antes de sincronizar.
      await equipo.entradas('e1', '10', hace2h);
      await equipo.entradas(
        'e2',
        '50',
        hace1h,
        estado: EstadoMovimiento.anulado,
      );

      await conciliar();

      expect(
        equipo.items.datos[tienda.getId()]!['i1']!.getStockActual(),
        d('10'),
      );
    });

    test('no mira los ítems sin movimientos desde la fecha', () async {
      await equipo.entradas(
        'e1',
        '10',
        desde.subtract(const Duration(days: 2)),
      );

      await conciliar();

      // No se recalculó: sigue el número viejo.
      expect(
        equipo.items.datos[tienda.getId()]!['i1']!.getStockActual(),
        d('999'),
      );
    });

    test(
      'si el propietario lo acepta así no se vuelve a avisar del ítem',
      () async {
        await equipo.entradas('e1', '10', hace2h);
        await equipo.salida('s1', '16', hace1h);
        final primero = (await conciliar()).single;
        primero.setResuelto(true);
        await equipo.salida('s2', '1', hace1h);

        final otraVez = await conciliar();

        expect(otraVez, isEmpty);
        expect(equipo.conflictos.todos(tienda), hasLength(1));
      },
    );

    test('un ítem de otra tienda no se mira', () async {
      await equipo.entradas('e1', '10', hace2h, en: otra);
      await equipo.salida('s1', '16', hace1h, en: otra);

      expect(await conciliar(), isEmpty);
    });
  });

  group('abono mayor que el saldo', () {
    Fiado fiado({
      String id = 'f1',
      String monto = '10000',
      DateTime? inicio,
      List<Abono> abonos = const [],
      String? saldo,
      EstadoFiado estado = EstadoFiado.pendiente,
    }) => Fiado.guardado(
      id,
      d(monto),
      inicio ?? desde.subtract(const Duration(days: 5)),
      Cliente('c1', 'María Pérez', '3001112222'),
      d(saldo ?? monto),
      estado,
      abonos,
    );
    Abono abono(
      String id,
      String monto,
      DateTime fecha, {
      bool anulado = false,
    }) =>
        Abono(id, d(monto), fecha, MedioPago.efectivo, null, anulado: anulado);

    test('recalcula el saldo, lo guarda y avisa si queda negativo', () async {
      equipo.fiados
          .de(tienda)
          .add(
            fiado(
              abonos: [
                abono('a1', '8000', hace2h),
                abono('a2', '8000', hace1h),
              ],
              saldo: '2000',
            ),
          );

      final nuevos = await conciliar();

      final c = nuevos.single;
      expect(c.getTipo(), TipoConflicto.abonoExcedeSaldo);
      expect(c.getIdsRegistros(), ['f1', 'a1', 'a2']);
      expect(c.getDescripcion(), contains('María Pérez'));
      expect(c.getEtiquetasRegistros().first, contains('Fiado de María Pérez'));
      expect(c.getEtiquetasRegistros()[1], contains(r'$ 8.000'));
      expect(equipo.fiados.actualizados, hasLength(1));
      expect(equipo.fiados.actualizados.single.getSaldoPendiente(), d('-6000'));
    });

    test('los abonos anulados no cuentan ni van en el conflicto', () async {
      equipo.fiados
          .de(tienda)
          .add(
            fiado(
              abonos: [
                abono('a1', '8000', hace2h),
                abono('a2', '8000', hace1h),
                abono('a3', '8000', hace1h, anulado: true),
              ],
              saldo: '2000',
            ),
          );

      final nuevos = await conciliar();

      expect(nuevos.single.getIdsRegistros(), ['f1', 'a1', 'a2']);
    });

    test(
      'un saldo que se corrige sin quedar negativo se guarda y no avisa',
      () async {
        equipo.fiados
            .de(tienda)
            .add(fiado(abonos: [abono('a1', '10000', hace1h)], saldo: '10000'));

        final nuevos = await conciliar();

        expect(nuevos, isEmpty);
        final guardado = equipo.fiados.actualizados.single;
        expect(guardado.getSaldoPendiente(), d('0'));
        expect(guardado.getEstado(), EstadoFiado.saldado);
      },
    );

    test('un saldo que ya estaba bien no se vuelve a guardar', () async {
      equipo.fiados
          .de(tienda)
          .add(fiado(abonos: [abono('a1', '4000', hace1h)], saldo: '6000'));

      final nuevos = await conciliar();

      expect(nuevos, isEmpty);
      expect(equipo.fiados.actualizados, isEmpty);
    });

    test('los fiados sin cambios desde la fecha no se miran', () async {
      equipo.fiados
          .de(tienda)
          .add(
            fiado(
              abonos: [
                abono('a1', '8000', desde.subtract(const Duration(days: 2))),
                abono('a2', '8000', desde.subtract(const Duration(days: 1))),
              ],
              saldo: '2000',
            ),
          );

      expect(await conciliar(), isEmpty);
      expect(equipo.fiados.actualizados, isEmpty);
    });

    test('un fiado anulado se ignora', () async {
      equipo.fiados
          .de(tienda)
          .add(
            fiado(
              abonos: [abono('a1', '8000', hace1h)],
              saldo: '0',
              estado: EstadoFiado.anulado,
            ),
          );

      expect(await conciliar(), isEmpty);
      expect(equipo.fiados.actualizados, isEmpty);
    });

    test(
      'un conflicto resuelto no vuelve a aparecer con los mismos abonos',
      () async {
        equipo.fiados
            .de(tienda)
            .add(
              fiado(
                abonos: [
                  abono('a1', '8000', hace2h),
                  abono('a2', '8000', hace1h),
                ],
                saldo: '2000',
              ),
            );
        (await conciliar()).single.setResuelto(true);

        expect(await conciliar(), isEmpty);
        expect(equipo.conflictos.todos(tienda), hasLength(1));
      },
    );
  });

  group('código repetido', () {
    Producto producto(String id, String interno, String nombre) =>
        Producto(id, interno, nombre, UnidadMedida.unidad, d('1'), d('2'));
    CodigoProducto codigo(String id, String valor) =>
        CodigoProducto(id, FormatoCodigo.ean13, valor);

    test('un código de barras en dos productos', () async {
      final a = producto('p1', 'G1', 'Galletas')
        ..agregarCodigo(codigo('k1', '7701234567895'));
      final b = producto('p2', 'G2', 'Galletas de coco')
        ..agregarCodigo(codigo('k2', '7701234567895'));
      equipo.productos.datos[tienda.getId()] = {'p1': a, 'p2': b};

      final nuevos = await conciliar();

      final c = nuevos.single;
      expect(c.getTipo(), TipoConflicto.codigoRepetido);
      expect(c.getIdsRegistros(), ['p1', 'p2']);
      expect(c.getDescripcion(), contains('7701234567895'));
      expect(c.getEtiquetasRegistros().first, contains('Galletas'));
    });

    test('un código interno repetido', () async {
      equipo.productos.datos[tienda.getId()] = {
        'p1': producto('p1', 'G1', 'Galletas'),
        'p2': producto('p2', 'G1', 'Galletas de coco'),
      };

      final nuevos = await conciliar();

      expect(nuevos.single.getTipo(), TipoConflicto.codigoRepetido);
      expect(nuevos.single.getDescripcion(), contains('interno G1'));
    });

    test('tres productos con el mismo código son un solo conflicto', () async {
      equipo.productos.datos[tienda.getId()] = {
        for (final i in ['p1', 'p2', 'p3'])
          i: producto(i, i.toUpperCase(), 'Producto $i')
            ..agregarCodigo(codigo('k$i', 'X')),
      };

      final nuevos = await conciliar();

      expect(nuevos.single.getIdsRegistros(), ['p1', 'p2', 'p3']);
    });

    test('códigos distintos, vacíos o repetidos en el mismo producto no son '
        'conflicto', () async {
      equipo.productos.datos[tienda.getId()] = {
        'p1': producto('p1', 'G1', 'Galletas')
          ..agregarCodigo(codigo('k1', 'AAA'))
          ..agregarCodigo(codigo('k2', 'AAA'))
          ..agregarCodigo(codigo('k3', '  ')),
        'p2': producto('p2', 'G2', 'Leche')..agregarCodigo(codigo('k4', 'BBB')),
        'p3': producto('p3', '', 'Pan')..agregarCodigo(codigo('k5', ' ')),
        'p4': producto('p4', ' ', 'Sal'),
      };

      expect(await conciliar(), isEmpty);
    });

    test('no se repite al conciliar otra vez', () async {
      equipo.productos.datos[tienda.getId()] = {
        'p1': producto('p1', 'G1', 'Galletas'),
        'p2': producto('p2', 'G1', 'Galletas de coco'),
      };
      await conciliar();

      expect(await conciliar(), isEmpty);
      expect(equipo.conflictos.todos(tienda), hasLength(1));
    });

    test('mira todos los productos aunque no sean recientes', () async {
      equipo.productos.datos[tienda.getId()] = {
        'p1': producto('p1', 'G1', 'Galletas'),
        'p2': producto('p2', 'G1', 'Galletas de coco'),
      }..forEach((_, p) => p.setActualizadoEn(DateTime.utc(2020)));

      expect(await conciliar(), hasLength(1));
    });
  });

  group('movimiento en caja cerrada', () {
    final dia = DateTime(2026, 11, 19);
    final cierre = DateTime.utc(2026, 11, 19, 18);

    MovimientoCaja movimiento(String id, DateTime fecha) => MovimientoCaja(
      id,
      d('5000'),
      'Pago de la luz',
      ClasificacionMovimiento.negocio,
      TipoMovimientoCaja.egreso,
      fecha,
    );

    Future<void> cajaCerrada({DateTime? fechaCierre}) async {
      await equipo.cajas.crear(tienda, Caja('c1', dia));
      await equipo.cajas.cerrar(
        tienda,
        Caja(
          'c1',
          dia,
          efectivoContado: d('10000'),
          diferencia: d('0'),
          fechaCierre: fechaCierre ?? cierre,
        ),
      );
    }

    test('un movimiento posterior al cierre de su caja', () async {
      await cajaCerrada();
      final tarde = movimiento('mc1', DateTime.utc(2026, 11, 19, 19));
      await equipo.cajas.registrarMovimiento(tienda, Caja('c1', dia), tarde);

      final nuevos = await conciliar();

      final c = nuevos.single;
      expect(c.getTipo(), TipoConflicto.movimientoCajaCerrada);
      expect(c.getIdsRegistros(), ['c1', 'mc1']);
      expect(c.getDescripcion(), contains('Pago de la luz'));
      expect(c.getDescripcion(), contains(r'$ 5.000'));
      expect(c.getEtiquetasRegistros().first, startsWith('Caja del '));
      expect(c.getEtiquetasRegistros().last, startsWith('Egreso de'));
    });

    test('un movimiento anterior al cierre no es conflicto', () async {
      await cajaCerrada();
      await equipo.cajas.registrarMovimiento(
        tienda,
        Caja('c1', dia),
        movimiento('mc1', DateTime.utc(2026, 11, 19, 17)),
      );

      expect(await conciliar(), isEmpty);
    });

    test('en una caja abierta no es conflicto', () async {
      await equipo.cajas.crear(tienda, Caja('c1', dia));
      await equipo.cajas.registrarMovimiento(
        tienda,
        Caja('c1', dia),
        movimiento('mc1', DateTime.utc(2026, 11, 19, 19)),
      );

      expect(await conciliar(), isEmpty);
    });

    test('un movimiento sin caja guardada se ignora', () async {
      await equipo.cajas.registrarMovimiento(
        tienda,
        Caja('c1', dia),
        movimiento('mc1', DateTime.utc(2026, 11, 19, 19)),
      );

      expect(await conciliar(), isEmpty);
    });

    test('no se repite al conciliar otra vez', () async {
      await cajaCerrada();
      await equipo.cajas.registrarMovimiento(
        tienda,
        Caja('c1', dia),
        movimiento('mc1', DateTime.utc(2026, 11, 19, 19)),
      );
      await conciliar();

      expect(await conciliar(), isEmpty);
    });
  });

  group('varios choques y fallas', () {
    test('devuelve solo los nuevos, de todos los tipos, en el orden del '
        'diagrama', () async {
      await equipo.entradas('e1', '24', hace2h, factura: 'FV1');
      await equipo.entradas('e2', '24', hace1h, factura: 'FV1');
      await equipo.entradas('e3', '1', hace1h, item: equipo.cafe);
      await equipo.salida('s1', '5', hace1h, item: equipo.cafe);
      equipo.productos.datos[tienda.getId()] = {
        'p1': Producto('p1', 'G1', 'A', UnidadMedida.unidad, d('1'), d('2')),
        'p2': Producto('p2', 'G1', 'B', UnidadMedida.unidad, d('1'), d('2')),
      };

      final nuevos = await conciliar();

      expect(nuevos.map((c) => c.getTipo()), [
        TipoConflicto.posibleDuplicado,
        TipoConflicto.stockNegativo,
        TipoConflicto.codigoRepetido,
      ]);
      expect(await conciliar(), isEmpty);
    });

    test(
      'si algo falla no se guarda nada: ni conflictos ni el estado EN_REVISION',
      () async {
        await equipo.entradas('e1', '24', hace2h, factura: 'FV1');
        final segunda = await equipo.entradas(
          'e2',
          '24',
          hace1h,
          factura: 'FV1',
        );
        equipo.movimientos.fallarActualizarEstado = true;

        await expectLater(conciliar(), throwsA(isA<StateError>()));

        expect(equipo.conflictos.todos(tienda), isEmpty);
        expect(segunda.getEstado(), EstadoMovimiento.vigente);
      },
    );

    test('una tienda no ve ni toca los choques de otra', () async {
      await equipo.entradas('e1', '24', hace2h, factura: 'FV1', en: otra);
      await equipo.entradas('e2', '24', hace1h, factura: 'FV1', en: otra);

      expect(await conciliar(), isEmpty);
      expect(equipo.conflictos.todos(otra), isEmpty);
    });
  });
}

/// Un equipo: repositorios en memoria y un [ServicioConciliacion] con ellos.
class _Equipo {
  _Equipo(DateTime ahora) {
    unidad = UnidadTrabajoFalsa([
      conflictos,
      movimientos,
      items,
      cajas,
      fiados,
      productos,
    ]);
    for (final r in [
      conflictos,
      movimientos,
      items,
      cajas,
      fiados,
      productos,
    ]) {
      (r as dynamic).unidad = unidad;
    }
    final huevoProducto = Producto(
      'p-huevo',
      'H1',
      'Huevo AA',
      UnidadMedida.unidad,
      Decimal.parse('400'),
      Decimal.parse('550'),
    );
    huevo = ItemInventario('i1', huevoProducto, Decimal.parse('999'));
    cafe = ItemInventario(
      'i2',
      Producto(
        'p-cafe',
        'C1',
        'Café',
        UnidadMedida.unidad,
        Decimal.parse('7000'),
        Decimal.parse('8900'),
      ),
      Decimal.parse('999'),
    );
    for (final i in [huevo, cafe]) {
      items.datos.putIfAbsent('t1', () => {})[i.getId()] = i;
    }
    servicio = ServicioConciliacion(
      conflictos,
      movimientos,
      fiados,
      cajas,
      productos,
      ServicioInventario(
        items,
        movimientos,
        Decimal.fromInt(5),
        unidad,
        productos,
      ),
      unidad,
      const [],
      reloj: () => ahora,
    );
  }

  final conflictos = ConflictoRepositorioFalso();
  final movimientos = MovimientoRepositorioFalso();
  final items = InventarioRepositorioFalso();
  final cajas = CajaRepositorioFalso();
  final fiados = FiadoRepositorioFalso();
  final productos = ProductoRepositorioFalso();
  late final UnidadTrabajoFalsa unidad;
  late final ServicioConciliacion servicio;
  late final ItemInventario huevo;
  late final ItemInventario cafe;

  Future<EntradaMercancia> entradas(
    String id,
    String cantidad,
    DateTime fecha, {
    String? factura,
    ItemInventario? item,
    EstadoMovimiento estado = EstadoMovimiento.vigente,
    Tienda? en,
  }) async {
    final m = EntradaMercancia(
      id,
      item ?? huevo,
      Decimal.parse(cantidad),
      fecha,
      Decimal.parse('400'),
      factura,
    )..setEstado(estado);
    await movimientos.guardar(en ?? Tienda('t1', 'T001', 'G', 'A'), m);
    return m;
  }

  Future<SalidaVenta> salida(
    String id,
    String cantidad,
    DateTime fecha, {
    ItemInventario? item,
    Tienda? en,
  }) async {
    final m = SalidaVenta(
      id,
      item ?? huevo,
      -Decimal.parse(cantidad),
      fecha,
      'v$id',
      Decimal.parse('550'),
      Decimal.parse('400'),
    );
    await movimientos.guardar(en ?? Tienda('t1', 'T001', 'G', 'A'), m);
    return m;
  }
}
