import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';

import 'fakes_catalogo.dart';
import 'fakes_inventario.dart';

void main() {
  final tienda = Tienda(
    '11111111-1111-4111-8111-111111111111',
    'T001',
    'Granero El Porvenir',
    'Arjona, Bolívar',
  );
  final uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );
  Decimal d(String v) => Decimal.parse(v);

  late InventarioRepositorioFalso items;
  late MovimientoRepositorioFalso movimientos;
  late UnidadTrabajoFalsa unidad;
  late ServicioInventario servicio;
  late Producto aceite;
  late ItemInventario itemAceite;

  setUp(() async {
    items = InventarioRepositorioFalso();
    movimientos = MovimientoRepositorioFalso();
    unidad = UnidadTrabajoFalsa([items, movimientos]);
    items.unidad = unidad;
    movimientos.unidad = unidad;
    servicio = ServicioInventario(items, movimientos, d('5'), unidad);
    aceite = Producto(
      'p1',
      'ACE-1',
      'Aceite 1 L',
      UnidadMedida.unidad,
      d('8600'),
      d('11000'),
    );
    itemAceite = ItemInventario('i1', aceite, d('8'));
    await items.guardarItem(tienda, itemAceite);
    items.guardadosEnTransaccion.clear();
  });

  Future<Decimal> stockGuardado() async =>
      (await items.buscarItem(tienda, aceite))!.getStockActual();

  Producto sinItem() =>
      Producto('p9', 'Z', 'Sin ítem', UnidadMedida.unidad, null, d('1'));

  /// Entrada anterior ya guardada en el historial.
  void entradaAnterior(
    String costo,
    DateTime fecha, {
    EstadoMovimiento estado = EstadoMovimiento.vigente,
  }) => movimientos
      .de(tienda)
      .add(
        EntradaMercancia(
          'e-${fecha.month}-${fecha.day}',
          itemAceite,
          d('10'),
          fecha,
          d(costo),
          null,
        )..setEstado(estado),
      );

  group('registrarEntrada', () {
    test('stock nuevo = stock anterior + cantidad', () async {
      final entrada = await servicio.registrarEntrada(
        tienda,
        aceite,
        d('24'),
        d('9400'),
        'FV-10231',
      );

      expect(entrada.getItem().getStockActual(), d('32'));
      expect(await stockGuardado(), d('32'));
      expect(movimientos.de(tienda), [entrada]);
      expect(entrada.getId(), matches(uuidV4));
      expect(entrada.getCantidad(), d('24'));
      expect(entrada.getCostoUnitario(), d('9400'));
      expect(entrada.getNumeroFactura(), 'FV-10231');
      expect(entrada.getEstado(), EstadoMovimiento.vigente);
      expect(entrada.getFecha().isUtc, isTrue);
    });

    test('acepta cantidades con decimales (kilos, libras)', () async {
      final entrada = await servicio.registrarEntrada(
        tienda,
        aceite,
        d('2.5'),
        d('3000'),
        null,
      );
      expect(entrada.getItem().getStockActual(), d('10.5'));
    });

    test('movimiento e ítem se guardan en una sola transacción', () async {
      await servicio.registrarEntrada(tienda, aceite, d('1'), d('1'), null);
      expect(unidad.transacciones, 1);
      expect(movimientos.guardadosEnTransaccion, [true]);
      expect(items.guardadosEnTransaccion, [true]);
    });

    for (final (cantidad, costo) in [
      ('0', '100'),
      ('-3', '100'),
      ('5', '-1'),
    ]) {
      test('rechaza cantidad $cantidad con costo $costo', () async {
        await expectLater(
          servicio.registrarEntrada(
            tienda,
            aceite,
            d(cantidad),
            d(costo),
            null,
          ),
          throwsA(
            isA<ExcepcionDatosEntradaNoValidos>().having(
              (e) => e.mensaje,
              'mensaje',
              'La cantidad debe ser mayor que cero y el costo no puede ser '
                  'negativo',
            ),
          ),
        );
        expect(movimientos.de(tienda), isEmpty);
        expect(await stockGuardado(), d('8'));
        expect(unidad.transacciones, 0);
      });
    }

    test('costo cero es válido', () async {
      final entrada = await servicio.registrarEntrada(
        tienda,
        aceite,
        d('1'),
        Decimal.zero,
        null,
      );
      expect(entrada.getCostoUnitario(), Decimal.zero);
    });

    for (final factura in <String?>[null, '', '   ']) {
      test('número de factura "$factura" se permite y queda nulo', () async {
        final entrada = await servicio.registrarEntrada(
          tienda,
          aceite,
          d('1'),
          d('100'),
          factura,
        );
        expect(entrada.getNumeroFactura(), isNull);
        expect(movimientos.de(tienda), hasLength(1));
      });
    }

    test('quita los espacios del número de factura', () async {
      final entrada = await servicio.registrarEntrada(
        tienda,
        aceite,
        d('1'),
        d('100'),
        '  FV-7 ',
      );
      expect(entrada.getNumeroFactura(), 'FV-7');
    });

    test('rechaza un producto sin ítem de inventario', () async {
      await expectLater(
        servicio.registrarEntrada(tienda, sinItem(), d('1'), d('1'), null),
        throwsA(
          isA<ExcepcionProductoSinInventario>().having(
            (e) => e.mensaje,
            'mensaje',
            'El producto no tiene inventario en esta tienda',
          ),
        ),
      );
      expect(movimientos.de(tienda), isEmpty);
    });

    test('si falla el guardado no se guarda nada (rollback)', () async {
      items.fallar = true;

      await expectLater(
        servicio.registrarEntrada(tienda, aceite, d('24'), d('9400'), null),
        throwsStateError,
      );

      expect(movimientos.de(tienda), isEmpty);
      items.fallar = false;
      expect(await stockGuardado(), d('8'));
    });
  });

  group('aplicarMovimiento', () {
    EntradaMercancia movimiento(String id, String cantidad) => EntradaMercancia(
      id,
      itemAceite,
      d(cantidad),
      DateTime.utc(2026, 11, 14),
      d('0'),
      null,
    );

    test('rechaza si el stock quedaría negativo y no guarda nada', () async {
      await expectLater(
        servicio.aplicarMovimiento(tienda, movimiento('m1', '-9')),
        throwsA(
          isA<ExcepcionStockNegativo>().having(
            (e) => e.mensaje,
            'mensaje',
            'No hay suficiente existencia del producto',
          ),
        ),
      );
      expect(movimientos.de(tienda), isEmpty);
      expect(await stockGuardado(), d('8'));
      expect(itemAceite.getStockActual(), d('8'));
    });

    test('permite dejar el stock exactamente en cero', () async {
      await servicio.aplicarMovimiento(tienda, movimiento('m2', '-8'));
      expect(await stockGuardado(), Decimal.zero);
    });

    test('si falla, el ítem en memoria conserva su stock anterior', () async {
      items.fallar = true;
      await expectLater(
        servicio.aplicarMovimiento(tienda, movimiento('m3', '5')),
        throwsStateError,
      );
      expect(itemAceite.getStockActual(), d('8'));
      expect(movimientos.de(tienda), isEmpty);
    });

    test('dentro de otra transacción se une a ella', () async {
      await unidad.ejecutar(() async {
        await servicio.registrarEntrada(tienda, aceite, d('1'), d('1'), null);
      });
      expect(unidad.transacciones, 1);
    });
  });

  group('costoDifiereDelHistorico', () {
    test('sin entradas anteriores no hay advertencia', () async {
      expect(
        await servicio.costoDifiereDelHistorico(tienda, aceite, d('9400')),
        isFalse,
      );
    });

    test('mismo costo que la última entrada: no difiere', () async {
      entradaAnterior('8600', DateTime.utc(2026, 11, 2));
      expect(
        await servicio.costoDifiereDelHistorico(tienda, aceite, d('8600.00')),
        isFalse,
      );
    });

    test('costo distinto al de la última entrada: difiere', () async {
      entradaAnterior('8000', DateTime.utc(2026, 10, 20));
      entradaAnterior('8600', DateTime.utc(2026, 11, 2));
      expect(
        await servicio.costoDifiereDelHistorico(tienda, aceite, d('9400')),
        isTrue,
      );
      // Compara con la última, no con una anterior.
      expect(
        await servicio.costoDifiereDelHistorico(tienda, aceite, d('8000')),
        isTrue,
      );
    });

    test('solo cuentan las entradas VIGENTES', () async {
      entradaAnterior('8600', DateTime.utc(2026, 11, 2));
      entradaAnterior(
        '9400',
        DateTime.utc(2026, 11, 5),
        estado: EstadoMovimiento.anulado,
      );
      entradaAnterior(
        '9500',
        DateTime.utc(2026, 11, 6),
        estado: EstadoMovimiento.enRevision,
      );
      expect(
        await servicio.costoDifiereDelHistorico(tienda, aceite, d('8600')),
        isFalse,
      );
      expect(
        await servicio.costoDifiereDelHistorico(tienda, aceite, d('9400')),
        isTrue,
      );
    });

    test('la advertencia no bloquea el registro', () async {
      entradaAnterior('8600', DateTime.utc(2026, 11, 2));
      expect(
        await servicio.costoDifiereDelHistorico(tienda, aceite, d('9400')),
        isTrue,
      );
      final entrada = await servicio.registrarEntrada(
        tienda,
        aceite,
        d('24'),
        d('9400'),
        null,
      );
      expect(entrada.getItem().getStockActual(), d('32'));
    });

    test('rechaza un producto sin ítem', () async {
      await expectLater(
        servicio.costoDifiereDelHistorico(tienda, sinItem(), d('1')),
        throwsA(isA<ExcepcionProductoSinInventario>()),
      );
    });
  });

  group('registrarMerma (CUS-03)', () {
    test('el stock baja en la cantidad y la merma queda negativa', () async {
      final merma = await servicio.registrarMerma(
        tienda,
        aceite,
        d('3'),
        MotivoMerma.danado,
      );

      expect(merma.getCantidad(), d('-3'));
      expect(merma.getItem().getStockActual(), d('5'));
      expect(await stockGuardado(), d('5'));
      expect(merma.getId(), matches(uuidV4));
      expect(merma.getFecha().isUtc, isTrue);
    });

    test('el motivo queda guardado con el movimiento', () async {
      await servicio.registrarMerma(
        tienda,
        aceite,
        d('1'),
        MotivoMerma.devueltoProveedor,
      );

      final guardada = movimientos.de(tienda).single as Merma;
      expect(guardada.getMotivo(), MotivoMerma.devueltoProveedor);
      expect(guardada.getCantidad(), d('-1'));
    });

    test('movimiento e ítem se guardan en una sola transacción', () async {
      await servicio.registrarMerma(tienda, aceite, d('1'), MotivoMerma.otro);
      expect(movimientos.guardadosEnTransaccion, [true]);
      expect(items.guardadosEnTransaccion, [true]);
    });

    test('acepta cantidades con decimales (kilos, libras)', () async {
      final merma = await servicio.registrarMerma(
        tienda,
        aceite,
        d('2.5'),
        MotivoMerma.vencido,
      );
      expect(merma.getItem().getStockActual(), d('5.5'));
    });

    test('permite sacar justo lo que hay (stock en cero)', () async {
      await servicio.registrarMerma(tienda, aceite, d('8'), MotivoMerma.otro);
      expect(await stockGuardado(), d('0'));
    });

    for (final cantidad in ['0', '-1']) {
      test('rechaza cantidad $cantidad y no guarda nada', () async {
        await expectLater(
          servicio.registrarMerma(
            tienda,
            aceite,
            d(cantidad),
            MotivoMerma.vencido,
          ),
          throwsA(
            isA<ExcepcionDatosMermaNoValidos>().having(
              (e) => e.mensaje,
              'mensaje',
              'La cantidad debe ser mayor que cero y el motivo es obligatorio',
            ),
          ),
        );
        expect(movimientos.de(tienda), isEmpty);
        expect(await stockGuardado(), d('8'));
      });
    }

    test('rechaza el motivo vacío y no guarda nada', () async {
      await expectLater(
        servicio.registrarMerma(tienda, aceite, d('1'), null),
        throwsA(isA<ExcepcionDatosMermaNoValidos>()),
      );
      expect(movimientos.de(tienda), isEmpty);
      expect(await stockGuardado(), d('8'));
    });

    test(
      'cantidad mayor a la existencia: rechazada sin guardar nada',
      () async {
        await expectLater(
          servicio.registrarMerma(tienda, aceite, d('8.5'), MotivoMerma.danado),
          throwsA(
            isA<ExcepcionCantidadSuperaExistencia>().having(
              (e) => e.mensaje,
              'mensaje',
              'La cantidad supera la existencia',
            ),
          ),
        );
        expect(movimientos.de(tienda), isEmpty);
        expect(movimientos.guardadosEnTransaccion, isEmpty);
        expect(items.guardadosEnTransaccion, isEmpty);
        expect(await stockGuardado(), d('8'));
      },
    );

    test('rechaza un producto sin ítem de inventario', () async {
      await expectLater(
        servicio.registrarMerma(tienda, sinItem(), d('1'), MotivoMerma.otro),
        throwsA(isA<ExcepcionProductoSinInventario>()),
      );
      expect(movimientos.de(tienda), isEmpty);
    });

    test('si falla el guardado no se guarda nada (rollback)', () async {
      items.fallar = true;
      await expectLater(
        servicio.registrarMerma(tienda, aceite, d('2'), MotivoMerma.vencido),
        throwsA(isA<StateError>()),
      );
      items.fallar = false;
      expect(movimientos.de(tienda), isEmpty);
      expect(await stockGuardado(), d('8'));
    });
  });

  group('hayExistencia (RN-01)', () {
    test('verdadero si el stock alcanza, incluso justo', () {
      expect(servicio.hayExistencia(itemAceite, d('7')), isTrue);
      expect(servicio.hayExistencia(itemAceite, d('8')), isTrue);
    });

    test('falso si pide más de lo que hay', () {
      expect(servicio.hayExistencia(itemAceite, d('8.5')), isFalse);
    });
  });
}
