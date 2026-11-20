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

  group('una entrada repetida varias veces es una sola tarjeta (DI-51)', () {
    ConflictoSincronizacion pareja(String id, String otra) =>
        ConflictoSincronizacion(
          id,
          TipoConflicto.posibleDuplicado,
          'Dos entradas iguales',
          ['e0', otra],
          fecha,
          etiquetasRegistros: ['Entrada original', 'Entrada $otra'],
        );

    test('cargar junta las parejas con la misma entrada original', () async {
      alConsultar().thenAnswer(
        (_) async => [pareja('d1', 'e1'), pareja('d2', 'e2'), stock()],
      );
      final vm = crear();

      await vm.cargar();

      expect(vm.conflictos.map((c) => c.getId()), ['d1', 'stk']);
      final tarjeta = vm.conflictos.first;
      expect(vm.registrosElegibles(tarjeta).map((r) => r.id), [
        'e0',
        'e1',
        'e2',
      ]);
      expect(vm.registrosElegibles(tarjeta).first.etiqueta, 'Entrada original');
      expect(vm.cantidadDeRegistros(tarjeta), 3);
      expect(vm.descripcionDe(tarjeta), contains('3 entradas iguales'));
    });

    test('una pareja sola conserva su descripción', () async {
      alConsultar().thenAnswer((_) async => [pareja('d1', 'e1')]);
      final vm = crear();
      await vm.cargar();

      expect(vm.descripcionDe(vm.conflictos.single), 'Dos entradas iguales');
      expect(vm.cantidadDeRegistros(vm.conflictos.single), 2);
    });

    test(
      'guardar anula las que no se marcaron, conflicto por conflicto',
      () async {
        alConsultar().thenAnswer(
          (_) async => [pareja('d1', 'e1'), pareja('d2', 'e2')],
        );
        alResolver().thenAnswer((_) async {});
        final vm = crear();
        await vm.cargar();
        final tarjeta = vm.conflictos.single;

        vm.marcar(tarjeta, 'e0', true);
        vm.marcar(tarjeta, 'e1', true);
        await vm.guardarDecision(tarjeta);

        final llamadas = verify(
          () => coordinador.resolver(any(), captureAny(), captureAny(), any()),
        ).captured;
        // d1 (e0, e1): las dos marcadas, no se anula nada. d2 (e0, e2): e2.
        expect((llamadas[0] as ConflictoSincronizacion).getId(), 'd1');
        expect(llamadas[1], isEmpty);
        expect((llamadas[2] as ConflictoSincronizacion).getId(), 'd2');
        expect(llamadas[3], ['e2']);
        expect(vm.mensajeListo, ConflictosViewModel.mensajeResuelto);
      },
    );

    test(
      'si solo se marca una repetida, la original también se anula',
      () async {
        alConsultar().thenAnswer(
          (_) async => [pareja('d1', 'e1'), pareja('d2', 'e2')],
        );
        alResolver().thenAnswer((_) async {});
        final vm = crear();
        await vm.cargar();
        final tarjeta = vm.conflictos.single;

        vm.marcar(tarjeta, 'e2', true);
        await vm.guardarDecision(tarjeta);

        final llamadas = verify(
          () => coordinador.resolver(any(), any(), captureAny(), any()),
        ).captured;
        expect(llamadas[0], ['e0', 'e1']);
        expect(llamadas[1], ['e0']);
      },
    );

    test('"son registros distintos" resuelve todos los conflictos del grupo '
        'sin anular nada', () async {
      alConsultar().thenAnswer(
        (_) async => [pareja('d1', 'e1'), pareja('d2', 'e2')],
      );
      alResolver().thenAnswer((_) async {});
      final vm = crear();
      await vm.cargar();

      await vm.resolverSinElegir(vm.conflictos.single);

      final llamadas = verify(
        () => coordinador.resolver(any(), captureAny(), captureAny(), any()),
      ).captured;
      expect((llamadas[0] as ConflictoSincronizacion).getId(), 'd1');
      expect(llamadas[1], isEmpty);
      expect((llamadas[2] as ConflictoSincronizacion).getId(), 'd2');
      expect(llamadas[3], isEmpty);
    });

    test(
      'si falla uno de los conflictos muestra el error y vuelve a leer',
      () async {
        var lecturas = 0;
        alConsultar().thenAnswer((_) async {
          lecturas++;
          return [pareja('d1', 'e1'), pareja('d2', 'e2')];
        });
        var llamadas = 0;
        alResolver().thenAnswer((_) async {
          if (++llamadas == 2) throw StateError('falla');
        });
        final vm = crear();
        await vm.cargar();

        await vm.resolverSinElegir(vm.conflictos.single);

        expect(vm.error, isNotNull);
        expect(vm.mensajeListo, isNull);
        expect(lecturas, 2, reason: 'vuelve a leer la lista');
      },
    );
  });
}
