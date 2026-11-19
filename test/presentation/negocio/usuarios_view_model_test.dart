import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/presentation/negocio/usuarios_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/errores_usuarios.dart';
import 'package:mocktail/mocktail.dart';

import 'datos_alertas.dart';
import 'usuarios_falsos.dart';

void main() {
  late GestionarUsuariosFalso coordinador;

  final carmen = propietariaAlertas.usuario;
  final luis = Empleado('u2', 'Luis Gómez', '1000000002');
  final ana = Empleado('u3', 'Ana Torres', '1000000003', activo: false);

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(carmen);
  });

  setUp(() => coordinador = GestionarUsuariosFalso());

  UsuariosViewModel crear({bool propietaria = true}) => UsuariosViewModel(
    coordinador,
    propietaria ? propietariaAlertas : empleadoAlertas,
  );

  When<Future<List<Usuario>>> alListar() =>
      when(() => coordinador.listarUsuarios(any(), any()));
  When<Future<Empleado>> alCrear() => when(
    () => coordinador.crearEmpleado(any(), any(), any(), any(), any(), any()),
  );
  When<Future<void>> alDesactivar() =>
      when(() => coordinador.desactivarUsuario(any(), any(), any()));

  group('cargar', () {
    test('trae la lista y la deja como llegó', () async {
      alListar().thenAnswer((_) async => [carmen, luis, ana]);
      final vm = crear();

      await vm.cargar();

      expect(vm.usuarios, [carmen, luis, ana]);
      expect(vm.errorCarga, isNull);
      expect(vm.cargando, isFalse);
      final args = verify(
        () => coordinador.listarUsuarios(captureAny(), captureAny()),
      ).captured;
      expect(args, [tiendaAlertas, carmen]);
    });

    test('el empleado ve el mensaje de solo propietario', () async {
      alListar().thenThrow(const ExcepcionSoloPropietario());
      final vm = crear(propietaria: false);

      await vm.cargar();

      expect(vm.errorCarga, 'Esta consulta es solo para el propietario');
      expect(vm.usuarios, isEmpty);
    });

    test('sin internet dice que se necesita', () async {
      alListar().thenThrow(const ExcepcionSinConexionUsuarios());
      final vm = crear();

      await vm.cargar();

      expect(
        vm.errorCarga,
        'Necesitas internet para ver y cambiar los usuarios',
      );
    });

    test('una falla inesperada da un mensaje para el tendero', () async {
      alListar().thenThrow(StateError('x'));
      final vm = crear();

      await vm.cargar();

      expect(vm.errorCarga, 'No se pudo completar. Intente de nuevo');
      expect(vm.cargando, isFalse);
    });

    test('tras un error, una lectura buena lo limpia', () async {
      alListar().thenThrow(StateError('x'));
      final vm = crear();
      await vm.cargar();

      alListar().thenAnswer((_) async => [carmen]);
      await vm.cargar();

      expect(vm.errorCarga, isNull);
      expect(vm.usuarios, [carmen]);
    });
  });

  group('reglas de la lista', () {
    test('esUsted compara con el usuario de la sesión', () {
      final vm = crear();

      expect(vm.esUsted(carmen), isTrue);
      expect(vm.esUsted(luis), isFalse);
    });

    test('solo un empleado activo se puede desactivar', () {
      final vm = crear();

      expect(vm.puedeDesactivarse(luis), isTrue);
      expect(vm.puedeDesactivarse(ana), isFalse);
      expect(vm.puedeDesactivarse(carmen), isFalse);
    });
  });

  group('agregar', () {
    setUp(() {
      alListar().thenAnswer((_) async => [carmen, luis]);
    });

    test('crea el empleado, avisa y vuelve a leer la lista', () async {
      alCrear().thenAnswer(
        (_) async => Empleado('u9', 'Daniel Mendoza', '1045678901'),
      );
      final vm = crear();

      final creado = await vm.agregar(
        'Daniel Mendoza',
        '1045678901',
        'x@gip.test',
        'gip12345',
      );

      expect(creado, isTrue);
      expect(vm.mensajeListo, 'Empleado creado');
      expect(vm.error, isNull);
      expect(vm.ocupado, isFalse);
      final args = verify(
        () => coordinador.crearEmpleado(
          captureAny(),
          captureAny(),
          captureAny(),
          captureAny(),
          captureAny(),
          captureAny(),
        ),
      ).captured;
      expect(args, [
        tiendaAlertas,
        'Daniel Mendoza',
        '1045678901',
        'x@gip.test',
        'gip12345',
        carmen,
      ]);
      verify(() => coordinador.listarUsuarios(any(), any())).called(1);
      expect(vm.usuarios, [carmen, luis]);
    });

    test(
      'datos no válidos: muestra el mensaje del diagrama y no limpia',
      () async {
        alCrear().thenThrow(const ExcepcionDatosUsuarioNoValidos());
        final vm = crear();

        final creado = await vm.agregar('', '1', 'x@gip.test', 'gip12345');

        expect(creado, isFalse);
        expect(
          vm.error,
          'El nombre es obligatorio y la cédula no puede estar repetida',
        );
        expect(vm.mensajeListo, isNull);
      },
    );

    test('correo no válido, contraseña corta y correo ya registrado muestran '
        'su mensaje', () async {
      final vm = crear();

      alCrear().thenThrow(const ExcepcionCorreoNoValido());
      await vm.agregar('Ana', '1', 'mal', 'gip12345');
      expect(vm.error, 'Escribe un correo válido');

      alCrear().thenThrow(const ExcepcionClaveNoValida(6));
      await vm.agregar('Ana', '1', 'a@gip.test', '123');
      expect(vm.error, 'La contraseña debe tener al menos 6 caracteres');

      alCrear().thenThrow(const ExcepcionCorreoYaRegistrado());
      await vm.agregar('Ana', '1', 'a@gip.test', 'gip12345');
      expect(vm.error, 'Ese correo ya tiene una cuenta. Usa otro correo');

      alCrear().thenThrow(const ExcepcionCuentaNoCreada());
      await vm.agregar('Ana', '1', 'a@gip.test', 'gip12345');
      expect(
        vm.error,
        'No se pudo crear la cuenta de acceso. Inténtalo de nuevo',
      );
      expect(vm.mensajeListo, isNull);
    });

    test('el empleado ve el mensaje de solo propietario', () async {
      alCrear().thenThrow(const ExcepcionSoloPropietario());
      final vm = crear(propietaria: false);

      await vm.agregar('Ana', '1', 'x@gip.test', 'gip12345');

      expect(vm.error, 'Esta consulta es solo para el propietario');
    });

    test('una falla inesperada da un mensaje para el tendero', () async {
      alCrear().thenThrow(StateError('x'));
      final vm = crear();

      await vm.agregar('Ana', '1', 'x@gip.test', 'gip12345');

      expect(vm.error, 'No se pudo completar. Intente de nuevo');
      expect(vm.ocupado, isFalse);
    });

    test('un intento nuevo borra el mensaje anterior', () async {
      alCrear().thenThrow(const ExcepcionDatosUsuarioNoValidos());
      final vm = crear();
      await vm.agregar('', '1', 'x@gip.test', 'gip12345');
      expect(vm.error, isNotNull);

      alCrear().thenAnswer((_) async => Empleado('u9', 'Ana', '2'));
      await vm.agregar('Ana', '2', 'x@gip.test', 'gip12345');

      expect(vm.error, isNull);
      expect(vm.mensajeListo, 'Empleado creado');
    });

    test(
      'si no se puede releer la lista, queda la anterior y el aviso',
      () async {
        alCrear().thenAnswer((_) async => Empleado('u9', 'Ana', '2'));
        final vm = crear();
        await vm.cargar();
        alListar().thenThrow(const ExcepcionSinConexionUsuarios());

        final creado = await vm.agregar('Ana', '2', 'x@gip.test', 'gip12345');

        expect(creado, isTrue);
        expect(vm.mensajeListo, 'Empleado creado');
        expect(vm.usuarios, [carmen, luis]);
        expect(vm.ocupado, isFalse);
      },
    );

    test('mientras guarda no deja agregar otro', () async {
      final espera = Completer<Empleado>();
      alCrear().thenAnswer((_) => espera.future);
      final vm = crear();

      final primero = vm.agregar('Ana', '1', 'x@gip.test', 'gip12345');
      expect(vm.ocupado, isTrue);
      expect(await vm.agregar('Pedro', '2', 'x@gip.test', 'gip12345'), isFalse);
      espera.complete(Empleado('u9', 'Ana', '1'));
      await primero;

      verify(
        () =>
            coordinador.crearEmpleado(any(), any(), any(), any(), any(), any()),
      ).called(1);
    });
  });

  group('desactivar', () {
    setUp(() {
      alListar().thenAnswer((_) async => [carmen, luis, ana]);
    });

    test('desactiva, avisa y vuelve a leer la lista', () async {
      alDesactivar().thenAnswer((_) async {});
      final vm = crear();

      await vm.desactivar(luis);

      expect(vm.mensajeListo, 'Empleado desactivado');
      expect(vm.error, isNull);
      final args = verify(
        () => coordinador.desactivarUsuario(
          captureAny(),
          captureAny(),
          captureAny(),
        ),
      ).captured;
      expect(args, [tiendaAlertas, luis, carmen]);
      verify(() => coordinador.listarUsuarios(any(), any())).called(1);
    });

    test('si falla, avisa y vuelve a leer la lista del servidor', () async {
      alDesactivar().thenThrow(const ExcepcionSinConexionUsuarios());
      final vm = crear();

      await vm.desactivar(luis);

      expect(vm.error, 'Necesitas internet para ver y cambiar los usuarios');
      expect(vm.mensajeListo, isNull);
      // El usuario ya pudo quedar inactivo en memoria: se relee del servidor.
      verify(() => coordinador.listarUsuarios(any(), any())).called(1);
      expect(vm.ocupado, isFalse);
    });

    test('al propietario: "El propietario no se puede desactivar"', () async {
      alDesactivar().thenThrow(const ExcepcionNoSePuedeDesactivar());
      final vm = crear();

      await vm.desactivar(carmen);

      expect(vm.error, 'El propietario no se puede desactivar');
    });

    test('mientras desactiva no deja hacerlo otra vez', () async {
      final espera = Completer<void>();
      alDesactivar().thenAnswer((_) => espera.future);
      final vm = crear();

      final primero = vm.desactivar(luis);
      expect(vm.ocupado, isTrue);
      await vm.desactivar(luis);
      espera.complete();
      await primero;

      verify(() => coordinador.desactivarUsuario(any(), any(), any()))
          .called(1);
    });
  });
}
