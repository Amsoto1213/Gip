import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/presentation/caja/caja_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/errores_caja.dart';
import 'package:mocktail/mocktail.dart';

import 'caja_falsos.dart';

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final propietario = Administrador('2222', 'Carmen', '1000000001');

  late RegistrarMovimientoCajaFalso coordinador;
  late RegistrarCierreCajaFalso cierre;
  late CajaViewModel vm;

  MovimientoCaja movimiento(String valor, String descripcion) => MovimientoCaja(
    'm1',
    Decimal.parse(valor),
    descripcion,
    ClasificacionMovimiento.negocio,
    TipoMovimientoCaja.egreso,
    DateTime.utc(2026, 11, 18, 15),
  );

  When<Future<MovimientoCaja>> cuandoRegistra() => when(
    () => coordinador.registrarMovimiento(
      any(),
      any(),
      any(),
      any(),
      any(),
      any(),
    ),
  );

  setUpAll(() {
    registerFallbackValue(tienda);
    registerFallbackValue(TipoMovimientoCaja.egreso);
    registerFallbackValue(ClasificacionMovimiento.negocio);
    registerFallbackValue(Decimal.zero);
    registerFallbackValue(propietario);
  });

  setUp(() {
    coordinador = RegistrarMovimientoCajaFalso();
    cierre = RegistrarCierreCajaFalso();
    vm = CajaViewModel(coordinador, cierre, (
      usuario: propietario,
      tienda: tienda,
    ));
  });

  test('empieza en "Sale dinero" y "Del negocio", como el mockup', () {
    expect(vm.tipo, TipoMovimientoCaja.egreso);
    expect(vm.clasificacion, ClasificacionMovimiento.negocio);
  });

  test('anota con lo elegido y entrega el usuario activo', () async {
    cuandoRegistra().thenAnswer((_) async => movimiento('40000', 'Retiro'));
    vm
      ..elegirClasificacion(ClasificacionMovimiento.personal)
      ..elegirTipo(TipoMovimientoCaja.ingreso);

    final ok = await vm.anotar(valor: r'$ 40.000', descripcion: ' Retiro ');

    expect(ok, isTrue);
    verify(
      () => coordinador.registrarMovimiento(
        tienda,
        TipoMovimientoCaja.ingreso,
        ClasificacionMovimiento.personal,
        Decimal.parse('40000'),
        'Retiro',
        propietario,
      ),
    ).called(1);
    expect(vm.registrado?.getDescripcion(), 'Retiro');
    expect(vm.error, isNull);
    expect(vm.guardando, isFalse);
  });

  test('un valor vacío, cero, negativo o no numérico no llama al '
      'coordinador', () async {
    for (final valor in ['', '0', '-5', 'abc']) {
      expect(await vm.anotar(valor: valor, descripcion: 'x'), isFalse);
      expect(vm.error, 'El valor debe ser mayor que cero', reason: valor);
    }
    verifyNever(
      () => coordinador.registrarMovimiento(
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
      ),
    );
  });

  test('muestra el mensaje de negocio del rechazo', () async {
    cuandoRegistra().thenThrow(const ExcepcionCajaCerrada());

    expect(await vm.anotar(valor: '1.000', descripcion: 'x'), isFalse);

    expect(vm.error, 'La caja de hoy ya está cerrada');
    expect(vm.registrado, isNull);
  });

  test('un empleado recibe el rechazo de acceso', () async {
    cuandoRegistra().thenThrow(const ExcepcionSoloPropietario());

    await vm.anotar(valor: '1.000', descripcion: 'x');

    expect(vm.error, 'Solo el propietario de la tienda puede hacer esto');
  });

  test('un fallo inesperado da un mensaje para el tendero', () async {
    cuandoRegistra().thenThrow(StateError('disco'));

    await vm.anotar(valor: '1.000', descripcion: 'x');

    expect(vm.error, 'No se pudo anotar el movimiento. Inténtalo de nuevo');
    expect(vm.guardando, isFalse);
  });

  test(
    'un nuevo intento borra el error y la confirmación anteriores',
    () async {
      cuandoRegistra().thenAnswer((_) async => movimiento('1000', 'a'));
      await vm.anotar(valor: '1.000', descripcion: 'a');
      expect(vm.registrado, isNotNull);

      await vm.anotar(valor: '0', descripcion: 'b');

      expect(vm.registrado, isNull);
      expect(vm.error, isNotNull);
    },
  );

  test('ANULACION no se puede elegir', () {
    vm.elegirClasificacion(ClasificacionMovimiento.anulacion);
    expect(vm.clasificacion, ClasificacionMovimiento.negocio);
  });

  group('saldo esperado (CUS-14)', () {
    When<Future<Decimal>> cuandoConsulta() =>
        when(() => cierre.consultarSaldoEsperado(any(), any()));

    test('cargarSaldo guarda lo que debe haber en caja', () async {
      cuandoConsulta().thenAnswer((_) async => Decimal.parse('318500'));
      expect(vm.saldoEsperado, isNull);

      await vm.cargarSaldo();

      expect(vm.saldoEsperado, Decimal.parse('318500'));
      verify(() => cierre.consultarSaldoEsperado(tienda, propietario))
          .called(1);
    });

    test(
      'si no se puede consultar (p. ej. un empleado), no hay saldo',
      () async {
        cuandoConsulta().thenThrow(const ExcepcionSoloPropietario());

        await vm.cargarSaldo();

        expect(vm.saldoEsperado, isNull);
        expect(vm.error, isNull);
      },
    );

    test('al anotar un movimiento vuelve a consultar el saldo', () async {
      cuandoRegistra().thenAnswer((_) async => movimiento('1000', 'a'));
      cuandoConsulta().thenAnswer((_) async => Decimal.parse('99000'));

      await vm.anotar(valor: '1.000', descripcion: 'a');

      expect(vm.saldoEsperado, Decimal.parse('99000'));
    });

    test('si el movimiento se rechaza no vuelve a consultar', () async {
      cuandoRegistra().thenThrow(const ExcepcionCajaCerrada());

      await vm.anotar(valor: '1.000', descripcion: 'a');

      verifyNever(() => cierre.consultarSaldoEsperado(any(), any()));
    });
  });
}
