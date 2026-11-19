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
  late CuentaAccesoFalsa cuentas;
  late ServicioUsuarios servicio;
  late Administrador carmen;

  setUp(() {
    usuarios = UsuarioRepositorioFalso();
    cuentas = CuentaAccesoFalsa();
    servicio = ServicioUsuarios(usuarios, cuentas);
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
    Future<Empleado> crear([
      String nombre = 'Daniel Mendoza',
      String cedula = '1045678901',
      String correo = 'daniel@gip.test',
      String clave = 'gip12345',
    ]) => servicio.crearEmpleado(tienda, nombre, cedula, correo, clave);

    test('crea la cuenta y el Empleado activo, con id uuid y correo', () async {
      final empleado = await crear();

      expect(empleado, isA<Empleado>());
      expect(empleado.isActivo(), isTrue);
      expect(empleado.getNombre(), 'Daniel Mendoza');
      expect(empleado.getCedula(), '1045678901');
      expect(empleado.getCorreo(), 'daniel@gip.test');
      expect(empleado.getId(), matches(uuid));
      expect(cuentas.cuentas, {'daniel@gip.test': 'gip12345'});
      expect(usuarios.guardados.map((u) => u.getId()), [empleado.getId()]);
      final guardado = await usuarios.buscarPorCedula(tienda, '1045678901');
      expect(guardado, isA<Empleado>());
      expect(guardado!.getCorreo(), 'daniel@gip.test');
      expect(guardado.isActivo(), isTrue);
    });

    test('cada empleado nuevo tiene un id distinto', () async {
      final a = await crear('A', '1', 'a@gip.test');
      final b = await crear('B', '2', 'b@gip.test');

      expect(a.getId(), isNot(b.getId()));
    });

    test('quita los espacios del nombre, la cédula y el correo, y pasa el '
        'correo a minúsculas (así lo busca el inicio de sesión)', () async {
      final empleado = await crear(
        '  Daniel Mendoza ',
        ' 1045678901  ',
        '  Daniel@GIP.test ',
      );

      expect(empleado.getNombre(), 'Daniel Mendoza');
      expect(empleado.getCedula(), '1045678901');
      expect(empleado.getCorreo(), 'daniel@gip.test');
      expect(cuentas.intentos.single.$1, 'daniel@gip.test');
    });

    test('la contraseña va tal cual a la cuenta, sin recortarla', () async {
      await crear('Daniel', '1', 'd@gip.test', ' gip 12345 ');

      expect(cuentas.cuentas['d@gip.test'], ' gip 12345 ');
    });

    test('la contraseña nunca queda en el usuario guardado', () async {
      await crear();

      final texto = usuarios.guardados.map((u) => '$u').join();
      expect(texto, isNot(contains('gip12345')));
    });

    for (final nombre in ['', '   ']) {
      test(
        'nombre vacío ("$nombre"): "Datos no válidos" y no crea nada',
        () async {
          await expectLater(
            crear(nombre),
            throwsA(isA<ExcepcionDatosUsuarioNoValidos>()),
          );
          expect(usuarios.guardados, isEmpty);
          expect(cuentas.intentos, isEmpty);
        },
      );
    }

    for (final cedula in ['', '  ']) {
      test(
        'cédula vacía ("$cedula"): "Datos no válidos" y no crea nada',
        () async {
          await expectLater(
            crear('Daniel', cedula),
            throwsA(isA<ExcepcionDatosUsuarioNoValidos>()),
          );
          expect(usuarios.guardados, isEmpty);
          expect(cuentas.intentos, isEmpty);
        },
      );
    }

    test('el mensaje de datos no válidos es el del diagrama', () async {
      await expectLater(
        crear(''),
        throwsA(
          isA<ExcepcionDatosUsuarioNoValidos>().having(
            (e) => e.mensaje,
            'mensaje',
            'El nombre es obligatorio y la cédula no puede estar repetida',
          ),
        ),
      );
    });

    test(
      'cédula repetida: "Datos no válidos" y NO se crea la cuenta',
      () async {
        await expectLater(
          crear('Otra Carmen', '1000000001'),
          throwsA(isA<ExcepcionDatosUsuarioNoValidos>()),
        );
        expect(usuarios.guardados, isEmpty);
        // Se revisa antes de crear la cuenta: no queda una cuenta sin empleado.
        expect(cuentas.intentos, isEmpty);
      },
    );

    test(
      'la cédula de un usuario inactivo también cuenta como repetida',
      () async {
        usuarios.sembrar(tienda, Empleado('u3', 'Ana', '777')..desactivar());

        await expectLater(
          crear('Otra Ana', '777'),
          throwsA(isA<ExcepcionDatosUsuarioNoValidos>()),
        );
      },
    );

    test('la misma cédula en otra tienda sí se permite', () async {
      usuarios.sembrar(otraTienda, Empleado('u9', 'Pedro', '555'));

      final empleado = await crear('Pedro', '555');

      expect(empleado.getCedula(), '555');
      expect((await servicio.listar(tienda)), hasLength(2));
    });

    test('la cédula repetida se busca con la cédula ya sin espacios', () async {
      await expectLater(
        crear('Otra Carmen', ' 1000000001 '),
        throwsA(isA<ExcepcionDatosUsuarioNoValidos>()),
      );
    });

    for (final correo in [
      '',
      '   ',
      'sin-arroba',
      'a@b',
      '@gip.test',
      'a@.com',
      'dos palabras@gip.test',
      'a@@gip.test',
    ]) {
      test('correo no válido ("$correo"): lo rechaza y no crea nada', () async {
        await expectLater(
          crear('Daniel', '1045678901', correo),
          throwsA(
            isA<ExcepcionCorreoNoValido>().having(
              (e) => e.mensaje,
              'mensaje',
              'Escribe un correo válido',
            ),
          ),
        );
        expect(cuentas.intentos, isEmpty);
        expect(usuarios.guardados, isEmpty);
      });
    }

    for (final clave in ['', '1', '12345']) {
      test('contraseña corta ("$clave"): lo rechaza y no crea nada', () async {
        await expectLater(
          crear('Daniel', '1045678901', 'd@gip.test', clave),
          throwsA(
            isA<ExcepcionClaveNoValida>().having(
              (e) => e.mensaje,
              'mensaje',
              'La contraseña debe tener al menos 6 caracteres',
            ),
          ),
        );
        expect(cuentas.intentos, isEmpty);
        expect(usuarios.guardados, isEmpty);
      });
    }

    test('seis caracteres es lo mínimo válido', () async {
      final empleado = await crear('Daniel', '1', 'd@gip.test', '123456');

      expect(empleado.getCorreo(), 'd@gip.test');
    });

    test('correo ya registrado con otra contraseña: error y no guarda al '
        'empleado', () async {
      cuentas.cuentas['luis@gip.test'] = 'otraclave';

      await expectLater(
        crear('Luis', '1000000002', 'luis@gip.test'),
        throwsA(isA<ExcepcionCorreoYaRegistrado>()),
      );
      expect(usuarios.guardados, isEmpty);
    });

    test('si crear la cuenta falla, el error llega y no se guarda al '
        'empleado', () async {
      cuentas.fallar = true;

      await expectLater(crear(), throwsA(isA<StateError>()));
      expect(usuarios.guardados, isEmpty);
    });

    test('si guardar falla, queda la cuenta y el mismo intento se puede '
        'repetir', () async {
      usuarios.fallarAlGuardar = true;
      await expectLater(crear(), throwsA(isA<StateError>()));
      expect(cuentas.cuentas, {'daniel@gip.test': 'gip12345'});
      usuarios.fallarAlGuardar = false;

      // El reintento con los mismos datos da por buena la cuenta ya creada.
      final empleado = await crear();

      expect(empleado.getCorreo(), 'daniel@gip.test');
      expect(usuarios.guardados, hasLength(1));
      expect(cuentas.intentos, hasLength(2));
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
