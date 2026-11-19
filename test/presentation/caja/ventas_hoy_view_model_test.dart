import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/pagos/anulacion_venta.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/presentation/caja/ventas_hoy_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/errores_caja.dart';
import 'package:mocktail/mocktail.dart';

import 'caja_falsos.dart';

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final propietario = Administrador('2222', 'Carmen', '1000000001');
  Decimal d(String v) => Decimal.parse(v);
  // Mediodía del 18 de noviembre: "hoy" para el view model.
  final ahora = DateTime(2026, 11, 18, 12);

  late AnularVentaFalso coordinador;
  late VentasHoyViewModel vm;

  Venta venta(String id, DateTime fecha, {List<dynamic>? formas}) => Venta(
    id,
    [
      ...(formas ?? [PagoContado('p-$id', d('5000'), d('0'))]),
    ].cast(),
    d('5000'),
    fecha,
  );

  SalidaVenta salida(String id, String nombre, Venta v) => SalidaVenta(
    id,
    ItemInventario(
      'i-$id',
      Producto('p-$id', id, nombre, UnidadMedida.unidad, null, d('1000')),
      d('5'),
    ),
    -d('1'),
    v.getFecha(),
    v,
    d('1000'),
    null,
  );

  setUpAll(() {
    registerFallbackValue(tienda);
    registerFallbackValue(propietario);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(<Venta>[]);
    registerFallbackValue(venta('x', DateTime(2026)));
  });

  setUp(() {
    coordinador = AnularVentaFalso();
    vm = VentasHoyViewModel(coordinador, (
      usuario: propietario,
      tienda: tienda,
    ), reloj: () => ahora);
    when(() => coordinador.listarVentas(any(), any(), any(), any()))
        .thenAnswer((_) async => []);
    when(() => coordinador.listarProductos(any(), any(), any()))
        .thenAnswer((_) async => {});
  });

  test('empieza en Hoy y carga el día completo con la tienda y el usuario '
      'activo', () async {
    await vm.elegirPeriodo(PeriodoVentas.hoy);

    expect(vm.periodo, PeriodoVentas.hoy);
    verify(
      () => coordinador.listarVentas(
        tienda,
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 19),
        propietario,
      ),
    ).called(1);
  });

  test('Ayer carga el día anterior', () async {
    await vm.elegirPeriodo(PeriodoVentas.ayer);

    verify(
      () => coordinador.listarVentas(
        tienda,
        DateTime(2026, 11, 17),
        DateTime(2026, 11, 18),
        propietario,
      ),
    ).called(1);
  });

  test(
    'Fechas incluye los dos días, ordena el rango y no pasa de hoy',
    () async {
      await vm.elegirFechas(DateTime(2026, 11, 20), DateTime(2026, 11, 10));

      expect(vm.periodo, PeriodoVentas.fechas);
      expect(vm.desde, DateTime(2026, 11, 10));
      expect(vm.hasta, DateTime(2026, 11, 18));
      verify(
        () => coordinador.listarVentas(
          tienda,
          DateTime(2026, 11, 10),
          DateTime(2026, 11, 19),
          propietario,
        ),
      ).called(1);
    },
  );

  test('las ventas salen de la más reciente a la más antigua', () async {
    final a = venta('a', DateTime(2026, 11, 18, 9));
    final b = venta('b', DateTime(2026, 11, 18, 11));
    when(() => coordinador.listarVentas(any(), any(), any(), any()))
        .thenAnswer((_) async => [a, b]);

    await vm.elegirPeriodo(PeriodoVentas.hoy);

    expect(vm.ventas.map((v) => v.getId()), ['b', 'a']);
  });

  test('nombresDe trae los productos de cada venta', () async {
    final a = venta('a', DateTime(2026, 11, 18, 9));
    when(() => coordinador.listarVentas(any(), any(), any(), any()))
        .thenAnswer((_) async => [a]);
    when(() => coordinador.listarProductos(any(), any(), any())).thenAnswer(
      (_) async => {
        'a': [salida('s1', 'Leche', a), salida('s2', 'Huevos', a)],
      },
    );

    await vm.elegirPeriodo(PeriodoVentas.hoy);

    expect(vm.nombresDe(a), ['Leche', 'Huevos']);
    expect(vm.nombresDe(venta('otra', ahora)), isEmpty);
  });

  group('pagoDe', () {
    test('Efectivo, Nequi, Fiado o varias juntas', () {
      final cliente = Cliente('c1', 'Ana', '');
      expect(VentasHoyViewModel.pagoDe(venta('a', ahora)), 'Efectivo');
      expect(
        VentasHoyViewModel.pagoDe(
          venta('b', ahora, formas: [PagoNequi('n', d('5000'), null)]),
        ),
        'Nequi',
      );
      expect(
        VentasHoyViewModel.pagoDe(
          venta(
            'c',
            ahora,
            formas: [
              PagoContado('p', d('2000'), d('0')),
              PagoNequi('n', d('1000'), null),
              Fiado('f', d('2000'), ahora, cliente),
            ],
          ),
        ),
        'Efectivo + Nequi + Fiado',
      );
    });
  });

  group('resumenDe', () {
    test('cuenta los productos vigentes y separa el efectivo, el fiado y '
        'Nequi', () async {
      final cliente = Cliente('c1', 'Ana', '');
      final v = venta(
        'm',
        ahora,
        formas: [
          PagoContado('p', d('10000'), d('2700')), // cubre 7.300
          PagoNequi('n', d('5000'), null),
          Fiado('f', d('3000'), ahora, cliente),
        ],
      );
      when(() => coordinador.listarVentas(any(), any(), any(), any()))
          .thenAnswer((_) async => [v]);
      when(() => coordinador.listarProductos(any(), any(), any())).thenAnswer(
        (_) async => {
          'm': [salida('s1', 'Leche', v), salida('s2', 'Huevos', v)],
        },
      );
      await vm.elegirPeriodo(PeriodoVentas.hoy);

      final r = vm.resumenDe(v);

      expect(r.productos, 2);
      expect(r.salenDeCaja, d('7300'));
      expect(r.devolverPorNequi, d('5000'));
      expect(r.fiadoAnulado, d('3000'));
    });
  });

  group('anular', () {
    final v = venta('a', DateTime(2026, 11, 18, 9));

    When<Future<AnulacionVenta>> cuandoAnula() =>
        when(() => coordinador.anularVenta(any(), any(), any(), any()));

    test('anula con el motivo y el usuario activo, avisa y vuelve a leer la '
        'lista', () async {
      when(() => coordinador.anularVenta(any(), any(), any(), any()))
          .thenAnswer(
            (_) async =>
                AnulacionVenta('x', propietario, ahora, 'Error al cobrar'),
          );

      final ok = await vm.anular(v, 'Error al cobrar');

      expect(ok, isTrue);
      expect(vm.aviso, 'Venta anulada');
      expect(vm.error, isNull);
      verify(
        () =>
            coordinador.anularVenta(tienda, v, 'Error al cobrar', propietario),
      ).called(1);
      verify(() => coordinador.listarVentas(any(), any(), any(), any()))
          .called(1);
    });

    test('con la caja cerrada muestra el mensaje y vuelve a leer', () async {
      cuandoAnula().thenThrow(const ExcepcionCajaCerrada());

      final ok = await vm.anular(v, 'Error al cobrar');

      expect(ok, isFalse);
      expect(vm.error, 'La caja de hoy ya está cerrada');
      expect(vm.aviso, isNull);
      verify(() => coordinador.listarVentas(any(), any(), any(), any()))
          .called(1);
    });

    test('un empleado recibe el rechazo de acceso', () async {
      cuandoAnula().thenThrow(const ExcepcionSoloPropietario());

      await vm.anular(v, 'x');

      expect(vm.error, 'Solo el propietario de la tienda puede hacer esto');
    });

    test('un fallo inesperado da un mensaje para el tendero', () async {
      cuandoAnula().thenThrow(StateError('disco'));

      await vm.anular(v, 'x');

      expect(vm.error, 'No se pudo anular la venta. Inténtalo de nuevo');
      expect(vm.anulando, isFalse);
    });
  });

  test('si no se pueden cargar las ventas, avisa', () async {
    when(() => coordinador.listarVentas(any(), any(), any(), any()))
        .thenThrow(const ExcepcionSoloPropietario());

    await vm.elegirPeriodo(PeriodoVentas.hoy);

    expect(vm.error, 'Solo el propietario de la tienda puede hacer esto');
    expect(vm.ventas, isEmpty);
  });

  test('cargar sin conservar mensajes borra el aviso anterior', () async {
    when(() => coordinador.anularVenta(any(), any(), any(), any()))
        .thenAnswer((_) async => AnulacionVenta('x', propietario, ahora, 'm'));
    await vm.anular(venta('a', ahora), 'm');
    expect(vm.aviso, isNotNull);

    await vm.elegirPeriodo(PeriodoVentas.ayer);

    expect(vm.aviso, isNull);
  });
}
