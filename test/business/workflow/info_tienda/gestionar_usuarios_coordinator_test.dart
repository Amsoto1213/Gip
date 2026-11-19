import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/info_tienda/servicio_usuarios.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/business/workflow/info_tienda/gestionar_usuarios_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/errores_usuarios.dart';
import 'package:mocktail/mocktail.dart';

import '../../componentes/info_tienda/fakes_usuarios.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

/// CUS-15: solo el propietario gestiona los usuarios; cada operación lo exige
/// (RNF-12).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final carmen = Administrador('u1', 'Carmen Ruiz', '1000000001');
  final luis = Empleado('u2', 'Luis Gómez', '1000000002');

  late UsuarioRepositorioFalso usuarios;
  late CuentaAccesoFalsa cuentas;
  late GestionarUsuariosCoordinator coordinador;

  setUp(() {
    usuarios = UsuarioRepositorioFalso()
      ..sembrar(tienda, carmen)
      ..sembrar(tienda, luis);
    cuentas = CuentaAccesoFalsa();
    coordinador = GestionarUsuariosCoordinator(
      ServicioUsuarios(usuarios, cuentas),
      ServicioAcceso(AutenticacionFalsa(), SesionLocalFalsa()),
    );
  });

  group('el propietario', () {
    test('lista los usuarios de la tienda', () async {
      final lista = await coordinador.listarUsuarios(tienda, carmen);

      expect(lista.map((u) => u.getNombre()), ['Carmen Ruiz', 'Luis Gómez']);
    });

    test('crea un empleado', () async {
      final empleado = await coordinador.crearEmpleado(
        tienda,
        'Ana Torres',
        '1000000003',
        'ana@gip.test',
        'gip12345',
        carmen,
      );

      expect(empleado, isA<Empleado>());
      expect(usuarios.guardados.single.getNombre(), 'Ana Torres');
      expect(usuarios.guardados.single.getCorreo(), 'ana@gip.test');
      // La cuenta con la que va a iniciar sesión.
      expect(cuentas.cuentas, {'ana@gip.test': 'gip12345'});
    });

    test('desactiva a un empleado', () async {
      await coordinador.desactivarUsuario(tienda, luis, carmen);

      expect(luis.isActivo(), isFalse);
      expect(usuarios.guardados.single.isActivo(), isFalse);
    });

    test('los errores del servicio llegan tal cual', () async {
      await expectLater(
        coordinador.crearEmpleado(
          tienda,
          '',
          '1',
          'a@gip.test',
          'gip12345',
          carmen,
        ),
        throwsA(isA<ExcepcionDatosUsuarioNoValidos>()),
      );
      await expectLater(
        coordinador.desactivarUsuario(tienda, carmen, carmen),
        throwsA(isA<ExcepcionNoSePuedeDesactivar>()),
      );
    });
  });

  group('el empleado no puede: acceso denegado y no se lee ni guarda nada', () {
    test('listar', () async {
      await expectLater(
        coordinador.listarUsuarios(tienda, luis),
        throwsA(isA<ExcepcionSoloPropietario>()),
      );
    });

    test('crear', () async {
      await expectLater(
        coordinador.crearEmpleado(
          tienda,
          'Ana',
          '3',
          'ana@gip.test',
          'gip12345',
          luis,
        ),
        throwsA(isA<ExcepcionSoloPropietario>()),
      );
      expect(usuarios.guardados, isEmpty);
      // Ni siquiera se crea la cuenta de acceso.
      expect(cuentas.intentos, isEmpty);
    });

    test('desactivar', () async {
      final otro = Empleado('u3', 'Pedro', '4');
      await expectLater(
        coordinador.desactivarUsuario(tienda, otro, luis),
        throwsA(isA<ExcepcionSoloPropietario>()),
      );
      expect(otro.isActivo(), isTrue);
      expect(usuarios.guardados, isEmpty);
    });

    test('ni siquiera consulta cuando falla la red', () async {
      usuarios.fallar = true;

      await expectLater(
        coordinador.listarUsuarios(tienda, luis),
        throwsA(isA<ExcepcionSoloPropietario>()),
      );
    });
  });
}
