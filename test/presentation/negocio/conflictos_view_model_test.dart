import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/presentation/negocio/conflictos_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/errores_conciliacion.dart';
import 'package:mocktail/mocktail.dart';

import 'conflictos_falsos.dart';
import 'datos_alertas.dart';

void main() {
  late RevisarConflictosFalso coordinador;
  final fecha = DateTime.utc(2026, 11, 19, 15, 45);

  ConflictoSincronizacion duplicado() => ConflictoSincronizacion(
    'dup',
    TipoConflicto.posibleDuplicado,
    'Dos entradas iguales',
    ['m1', 'm2'],
    fecha,
    etiquetasRegistros: ['Entrada A', 'Entrada B'],
  );
  ConflictoSincronizacion stock() => ConflictoSincronizacion(
    'stk',
    TipoConflicto.stockNegativo,
    'Huevo AA quedó en -6',
    ['m3', 'm4'],
    fecha,
  );
  ConflictoSincronizacion abono() => ConflictoSincronizacion(
    'abn',
    TipoConflicto.abonoExcedeSaldo,
    'Los abonos suman de más',
    ['f1', 'a1', 'a2'],
    fecha,
    etiquetasRegistros: ['Fiado de María', 'Abono 8.000', 'Abono 8.000 bis'],
  );
  ConflictoSincronizacion codigo() => ConflictoSincronizacion(
    'cod',
    TipoConflicto.codigoRepetido,
    'Dos productos con el mismo código',
    ['p1', 'p2'],
    fecha,
    etiquetasRegistros: ['Galletas', 'Galletas de coco'],
  );
  ConflictoSincronizacion caja() => ConflictoSincronizacion(
    'cja',
    TipoConflicto.movimientoCajaCerrada,
    'Llegó un movimiento a una caja cerrada',
    ['caja1', 'mc1'],
    fecha,
  );

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(duplicado());
    registerFallbackValue(propietariaAlertas.usuario);
  });

  setUp(() => coordinador = RevisarConflictosFalso());

  ConflictosViewModel crear({bool propietaria = true}) => ConflictosViewModel(
    coordinador,
    propietaria ? propietariaAlertas : empleadoAlertas,
  );

  When<Future<List<ConflictoSincronizacion>>> alConsultar() =>
      when(() => coordinador.consultarConflictos(any(), any()));
  When<Future<void>> alResolver() =>
      when(() => coordinador.resolver(any(), any(), any(), any()));

  List<dynamic> ultimaResolucion() => verify(
    () => coordinador.resolver(
      captureAny(),
      captureAny(),
      captureAny(),
      captureAny(),
    ),
  ).captured;

  group('cargar', () {
    test('trae los pendientes', () async {
      alConsultar().thenAnswer((_) async => [duplicado(), stock()]);
      final vm = crear();

      await vm.cargar();

      expect(vm.conflictos.map((c) => c.getId()), ['dup', 'stk']);
      expect(vm.errorCarga, isNull);
      expect(vm.cargando, isFalse);
      final args = verify(
        () => coordinador.consultarConflictos(captureAny(), captureAny()),
      ).captured;
      expect(args, [tiendaAlertas, propietariaAlertas.usuario]);
    });

    test('sin conflictos: lista vacía y sin error', () async {
      alConsultar().thenAnswer((_) async => []);
      final vm = crear();

      await vm.cargar();

      expect(vm.conflictos, isEmpty);
      expect(vm.errorCarga, isNull);
    });

    test('el empleado ve el mensaje de solo propietario', () async {
      alConsultar().thenThrow(const ExcepcionSoloPropietario());
      final vm = crear(propietaria: false);

      await vm.cargar();

      expect(vm.errorCarga, 'Esta consulta es solo para el propietario');
      expect(vm.conflictos, isEmpty);
    });

    test('una falla inesperada da un mensaje para el tendero', () async {
      alConsultar().thenThrow(StateError('x'));
      final vm = crear();

      await vm.cargar();

      expect(vm.errorCarga, 'No se pudo guardar la decisión. Intente de nuevo');
      expect(vm.cargando, isFalse);
    });
  });

  group('registros con casillas', () {
    test('posible duplicado y código repetido: todos los registros', () {
      final vm = crear();

      expect(vm.registrosElegibles(duplicado()).map((r) => r.id), ['m1', 'm2']);
      expect(vm.registrosElegibles(codigo()).map((r) => r.id), ['p1', 'p2']);
      expect(vm.registrosElegibles(duplicado()).first.etiqueta, 'Entrada A');
    });

    test('abono excedido: los abonos, sin el fiado', () {
      final vm = crear();

      expect(vm.registrosElegibles(abono()).map((r) => r.id), ['a1', 'a2']);
      expect(vm.registrosElegibles(abono()).first.etiqueta, 'Abono 8.000');
    });

    test('stock negativo y caja cerrada: nada que marcar', () {
      final vm = crear();

      expect(vm.registrosElegibles(stock()), isEmpty);
      expect(vm.registrosElegibles(caja()), isEmpty);
    });
  });

  group('casillas', () {
    test('marcar y desmarcar avisa y se puede consultar', () {
      final vm = crear();
      final c = duplicado();
      var avisos = 0;
      vm.addListener(() => avisos++);

      vm.marcar(c, 'm1', true);
      expect(vm.estaMarcado(c, 'm1'), isTrue);
      expect(vm.estaMarcado(c, 'm2'), isFalse);
      vm.marcar(c, 'm1', false);

      expect(vm.estaMarcado(c, 'm1'), isFalse);
      expect(avisos, 2);
    });

    test('las marcas son de cada conflicto', () {
      final vm = crear();

      vm.marcar(duplicado(), 'm1', true);

      expect(vm.estaMarcado(codigo(), 'm1'), isFalse);
    });

    test('solo se puede guardar la decisión con al menos una marcada', () {
      final vm = crear();
      final c = duplicado();

      expect(vm.puedeGuardarDecision(c), isFalse);
      vm.marcar(c, 'm1', true);
      expect(vm.puedeGuardarDecision(c), isTrue);
      vm.marcar(c, 'm1', false);
      expect(vm.puedeGuardarDecision(c), isFalse);
    });
  });

  group('guardar la decisión: qué ids viajan', () {
    setUp(() {
      alResolver().thenAnswer((_) async {});
      alConsultar().thenAnswer((_) async => []);
    });

    test(
      'posible duplicado: viajan las que NO se marcaron (se anulan)',
      () async {
        final vm = crear();
        final c = duplicado();
        vm.marcar(c, 'm1', true);

        await vm.guardarDecision(c);

        final args = ultimaResolucion();
        expect(args[0], tiendaAlertas);
        expect(args[1], same(c));
        expect(args[2], ['m2']);
        expect(args[3], propietariaAlertas.usuario);
      },
    );

    test('abono excedido: viajan los marcados', () async {
      final vm = crear();
      final c = abono();
      vm.marcar(c, 'a2', true);

      await vm.guardarDecision(c);

      expect(ultimaResolucion()[2], ['a2']);
    });

    test('código repetido: viajan los marcados', () async {
      final vm = crear();
      final c = codigo();
      vm.marcar(c, 'p2', true);

      await vm.guardarDecision(c);

      expect(ultimaResolucion()[2], ['p2']);
    });

    test(
      'los ids viajan en el orden del conflicto, no en el que se marcaron',
      () async {
        final vm = crear();
        final c = codigo();
        vm.marcar(c, 'p2', true);
        vm.marcar(c, 'p1', true);

        await vm.guardarDecision(c);

        expect(ultimaResolucion()[2], ['p1', 'p2']);
      },
    );

    test('resolverSinElegir manda la decisión vacía', () async {
      final vm = crear();
      final c = stock();

      await vm.resolverSinElegir(c);

      expect(ultimaResolucion()[2], isEmpty);
    });
  });

  group('resultado del intento', () {
    test(
      'resuelto: avisa, vuelve a leer la lista y olvida las marcas',
      () async {
        final c = duplicado();
        alConsultar().thenAnswer((_) async => [c, stock()]);
        alResolver().thenAnswer((_) async {});
        final vm = crear();
        await vm.cargar();
        vm.marcar(c, 'm1', true);
        alConsultar().thenAnswer((_) async => [stock()]);

        await vm.guardarDecision(c);

        expect(vm.mensajeListo, 'Conflicto resuelto');
        expect(vm.error, isNull);
        expect(vm.conflictos.map((x) => x.getId()), ['stk']);
        expect(vm.estaMarcado(c, 'm1'), isFalse);
        expect(vm.ocupado, isFalse);
      },
    );

    test('un error de negocio muestra su mensaje y deja las marcas', () async {
      final c = abono();
      alConsultar().thenAnswer((_) async => [c]);
      alResolver().thenThrow(const ExcepcionAbonoSigueExcedido());
      final vm = crear();
      await vm.cargar();
      vm.marcar(c, 'a2', true);

      await vm.guardarDecision(c);

      expect(
        vm.error,
        'Con esos abonos el fiado todavía queda con saldo negativo. Marque '
        'más abonos',
      );
      expect(vm.mensajeListo, isNull);
      // Sigue marcado en la lista que se volvió a leer.
      expect(vm.estaMarcado(c, 'a2'), isTrue);
    });

    test('el empleado ve el mensaje de solo propietario', () async {
      alResolver().thenThrow(const ExcepcionSoloPropietario());
      alConsultar().thenAnswer((_) async => []);
      final vm = crear(propietaria: false);

      await vm.resolverSinElegir(stock());

      expect(vm.error, 'Esta consulta es solo para el propietario');
    });

    test('una falla inesperada da un mensaje para el tendero', () async {
      alResolver().thenThrow(StateError('x'));
      alConsultar().thenAnswer((_) async => []);
      final vm = crear();

      await vm.resolverSinElegir(stock());

      expect(vm.error, 'No se pudo guardar la decisión. Intente de nuevo');
      expect(vm.ocupado, isFalse);
    });

    test('tras un intento fallido, siempre vuelve a leer la lista (lo que se '
        'cambió en memoria pudo no guardarse)', () async {
      alResolver().thenThrow(StateError('x'));
      alConsultar().thenAnswer((_) async => [duplicado()]);
      final vm = crear();

      await vm.resolverSinElegir(duplicado());

      verify(() => coordinador.consultarConflictos(any(), any())).called(1);
      expect(vm.conflictos, hasLength(1));
    });

    test('si no se puede releer, queda la lista anterior y el aviso', () async {
      final c = stock();
      alConsultar().thenAnswer((_) async => [c]);
      alResolver().thenAnswer((_) async {});
      final vm = crear();
      await vm.cargar();
      alConsultar().thenThrow(StateError('x'));

      await vm.resolverSinElegir(c);

      expect(vm.mensajeListo, 'Conflicto resuelto');
      expect(vm.conflictos, [c]);
      expect(vm.ocupado, isFalse);
    });

    test('un intento nuevo borra el mensaje anterior', () async {
      alResolver().thenThrow(StateError('x'));
      alConsultar().thenAnswer((_) async => []);
      final vm = crear();
      await vm.resolverSinElegir(stock());
      expect(vm.error, isNotNull);

      alResolver().thenAnswer((_) async {});
      await vm.resolverSinElegir(stock());

      expect(vm.error, isNull);
      expect(vm.mensajeListo, 'Conflicto resuelto');
    });
  });

  group('mientras guarda', () {
    test('bloquea otro intento y la decisión', () async {
      final espera = Completer<void>();
      alResolver().thenAnswer((_) => espera.future);
      alConsultar().thenAnswer((_) async => []);
      final vm = crear();
      final c = duplicado();
      vm.marcar(c, 'm1', true);

      final primero = vm.guardarDecision(c);
      expect(vm.ocupado, isTrue);
      expect(vm.puedeGuardarDecision(c), isFalse);
      await vm.resolverSinElegir(stock());
      espera.complete();
      await primero;

      verify(() => coordinador.resolver(any(), any(), any(), any())).called(1);
      expect(vm.ocupado, isFalse);
    });
  });
}
