import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/servicio_usuarios.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/errores_usuarios.dart';

import 'fakes_usuarios.dart';

/// ServicioUsuarios (CUS-15, DI-42).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otraTienda = Tienda('t2', 'T002', 'Tienda Dos', 'Turbaco');
  final uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  late UsuarioRepositorioFalso usuarios;
  late ServicioUsuarios servicio;
  late Administrador carmen;

  setUp(() {
    usuarios = UsuarioRepositorioFalso();
    servicio = ServicioUsuarios(usuarios);
    carmen = Administrador('u1', 'Carmen Ruiz', '1000000001');
    usuarios.sembrar(tienda, carmen);
  });

  group('listar', () {
    test('trae activos e inactivos: primero el propietario, luego por '
        'nombre', () async {
      final luis = Empleado('u2', 'Luis Gómez', '1000000002');
      final ana = Empleado('u3', 'Ana Torres', '1000000003')..desactivar();
      usuarios
        ..sembrar(tienda, luis)
        ..sembrar(tienda, ana);

      final lista = await servicio.listar(tienda);

      expect(lista.map((u) => u.getNombre()), [
        'Carmen Ruiz',
        'Ana Torres',
        'Luis Gómez',
      ]);
      expect(lista.map((u) => u.isActivo()), [true, false, true]);
    });

    test('solo los de la tienda pedida', () async {
      usuarios.sembrar(otraTienda, Empleado('u9', 'Ajeno', '999'));

      expect((await servicio.listar(tienda)).map((u) => u.getNombre()), [
        'Carmen Ruiz',
      ]);
    });
  });

  group('crearEmpleado', () {
    test('crea un Empleado activo con id uuid y lo guarda', () async {
      final empleado = await servicio.crearEmpleado(
        tienda,
        'Daniel Mendoza',
        '1045678901',
      );

      expect(empleado, isA<Empleado>());
      expect(empleado.isActivo(), isTrue);
      expect(empleado.getNombre(), 'Daniel Mendoza');
      expect(empleado.getCedula(), '1045678901');
      expect(empleado.getId(), matches(uuid));
      expect(usuarios.guardados.map((u) => u.getId()), [empleado.getId()]);
      final guardado = await usuarios.buscarPorCedula(tienda, '1045678901');
      expect(guardado, isA<Empleado>());
      expect(guardado!.getNombre(), 'Daniel Mendoza');
      expect(guardado.isActivo(), isTrue);
    });

    test('cada empleado nuevo tiene un id distinto', () async {
      final a = await servicio.crearEmpleado(tienda, 'A', '1');
      final b = await servicio.crearEmpleado(tienda, 'B', '2');

      expect(a.getId(), isNot(b.getId()));
    });

    test('quita los espacios del nombre y de la cédula', () async {
      final empleado = await servicio.crearEmpleado(
        tienda,
        '  Daniel Mendoza ',
        ' 1045678901  ',
      );

      expect(empleado.getNombre(), 'Daniel Mendoza');
      expect(empleado.getCedula(), '1045678901');
    });

    for (final nombre in ['', '   ']) {
      test(
        'nombre vacío ("$nombre"): "Datos no válidos" y no guarda',
        () async {
          await expectLater(
            servicio.crearEmpleado(tienda, nombre, '1045678901'),
            throwsA(isA<ExcepcionDatosUsuarioNoValidos>()),
          );
          expect(usuarios.guardados, isEmpty);
        },
      );
    }

    for (final cedula in ['', '  ']) {
      test(
        'cédula vacía ("$cedula"): "Datos no válidos" y no guarda',
        () async {
          await expectLater(
            servicio.crearEmpleado(tienda, 'Daniel', cedula),
            throwsA(isA<ExcepcionDatosUsuarioNoValidos>()),
          );
          expect(usuarios.guardados, isEmpty);
        },
      );
    }

    test('el mensaje es el del diagrama', () async {
      await expectLater(
        servicio.crearEmpleado(tienda, '', '1'),
        throwsA(
          isA<ExcepcionDatosUsuarioNoValidos>().having(
            (e) => e.mensaje,
            'mensaje',
            'El nombre es obligatorio y la cédula no puede estar repetida',
          ),
        ),
      );
    });

    test('cédula repetida: "Datos no válidos" y no guarda', () async {
      await expectLater(
        servicio.crearEmpleado(tienda, 'Otra Carmen', '1000000001'),
        throwsA(isA<ExcepcionDatosUsuarioNoValidos>()),
      );
      expect(usuarios.guardados, isEmpty);
    });

    test(
      'la cédula de un usuario inactivo también cuenta como repetida',
      () async {
        usuarios.sembrar(tienda, Empleado('u3', 'Ana', '777')..desactivar());

        await expectLater(
          servicio.crearEmpleado(tienda, 'Otra Ana', '777'),
          throwsA(isA<ExcepcionDatosUsuarioNoValidos>()),
        );
      },
    );

    test('la misma cédula en otra tienda sí se permite', () async {
      usuarios.sembrar(otraTienda, Empleado('u9', 'Pedro', '555'));

      final empleado = await servicio.crearEmpleado(tienda, 'Pedro', '555');

      expect(empleado.getCedula(), '555');
      expect((await servicio.listar(tienda)), hasLength(2));
    });

    test('la cédula repetida se busca con la cédula ya sin espacios', () async {
      await expectLater(
        servicio.crearEmpleado(tienda, 'Otra Carmen', ' 1000000001 '),
        throwsA(isA<ExcepcionDatosUsuarioNoValidos>()),
      );
    });

    test('si guardar falla, el error llega y no queda guardado', () async {
      usuarios.fallar = true;

      await expectLater(
        servicio.crearEmpleado(tienda, 'Daniel', '1045678901'),
        throwsA(isA<StateError>()),
      );
      usuarios.fallar = false;
      expect(usuarios.guardados, isEmpty);
      expect(await usuarios.buscarPorCedula(tienda, '1045678901'), isNull);
    });
  });

  group('desactivar', () {
    late Empleado luis;

    setUp(() {
      luis = Empleado('u2', 'Luis Gómez', '1000000002');
      usuarios.sembrar(tienda, luis);
    });

    test('desactiva al empleado y lo guarda, sin borrarlo', () async {
      await servicio.desactivar(tienda, luis);

      expect(luis.isActivo(), isFalse);
      expect(usuarios.guardados.map((u) => u.getId()), ['u2']);
      expect(usuarios.guardados.single.isActivo(), isFalse);
      final lista = await servicio.listar(tienda);
      expect(lista, hasLength(2));
      expect(lista.firstWhere((u) => u.getId() == 'u2').isActivo(), isFalse);
    });

    test(
      'al propietario no se le desactiva: "No se puede desactivar"',
      () async {
        await expectLater(
          servicio.desactivar(tienda, carmen),
          throwsA(
            isA<ExcepcionNoSePuedeDesactivar>().having(
              (e) => e.mensaje,
              'mensaje',
              'El propietario no se puede desactivar',
            ),
          ),
        );
        expect(carmen.isActivo(), isTrue);
        expect(usuarios.guardados, isEmpty);
      },
    );

    test('si ya está inactivo lo rechaza y no guarda', () async {
      luis.desactivar();

      await expectLater(
        servicio.desactivar(tienda, luis),
        throwsA(isA<ExcepcionUsuarioYaInactivo>()),
      );
      expect(usuarios.guardados, isEmpty);
    });

    test(
      'si guardar falla, el error llega y lo guardado sigue activo',
      () async {
        usuarios.fallar = true;

        await expectLater(
          servicio.desactivar(tienda, luis),
          throwsA(isA<StateError>()),
        );
        usuarios.fallar = false;
        expect(usuarios.guardados, isEmpty);
        expect(
          (await usuarios.buscarPorCedula(tienda, '1000000002'))!.isActivo(),
          isTrue,
        );
      },
    );
  });
}
