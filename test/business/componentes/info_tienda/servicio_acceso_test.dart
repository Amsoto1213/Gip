import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

void main() {
  final tienda = Tienda(
    '11111111-1111-4111-8111-111111111111',
    'T001',
    'Granero El Porvenir',
    'Arjona, Bolívar',
  );
  final UsuarioActivo carmen = (
    usuario: Administrador('2222', 'Carmen', '1000000001'),
    tienda: tienda,
  );

  late AutenticacionFalsa autenticacion;
  late SesionLocalFalsa sesionLocal;
  late ServicioAcceso servicio;

  setUpAll(() => registerFallbackValue(carmen));

  setUp(() {
    autenticacion = AutenticacionFalsa();
    sesionLocal = SesionLocalFalsa();
    servicio = ServicioAcceso(autenticacion, sesionLocal);
    when(() => sesionLocal.guardar(any())).thenAnswer((_) async {});
    when(() => sesionLocal.borrar()).thenAnswer((_) async {});
    when(() => autenticacion.cerrarSesion()).thenAnswer((_) async {});
  });

  group('iniciarSesion', () {
    test('rechaza el correo vacío sin consultar el servidor', () async {
      await expectLater(
        servicio.iniciarSesion('   ', 'gip12345'),
        throwsA(
          isA<ExcepcionDatoFaltante>().having(
            (e) => e.mensaje,
            'mensaje',
            'Escribe tu correo',
          ),
        ),
      );
      verifyNever(() => autenticacion.iniciarSesion(any(), any()));
    });

    test('rechaza la contraseña vacía sin consultar el servidor', () async {
      await expectLater(
        servicio.iniciarSesion('carmen@gip.test', ''),
        throwsA(
          isA<ExcepcionDatoFaltante>().having(
            (e) => e.mensaje,
            'mensaje',
            'Escribe tu contraseña',
          ),
        ),
      );
      verifyNever(() => autenticacion.iniciarSesion(any(), any()));
    });

    test('con la clave mala avisa y no guarda la sesión', () async {
      when(() => autenticacion.iniciarSesion('carmen@gip.test', 'mala'))
          .thenThrow(const ExcepcionCredencialesInvalidas());

      await expectLater(
        servicio.iniciarSesion('carmen@gip.test', 'mala'),
        throwsA(
          isA<ExcepcionCredencialesInvalidas>().having(
            (e) => e.mensaje,
            'mensaje',
            'Correo o contraseña incorrectos',
          ),
        ),
      );
      verifyNever(() => sesionLocal.guardar(any()));
    });

    test('con datos correctos devuelve el usuario y lo guarda', () async {
      when(() => autenticacion.iniciarSesion('carmen@gip.test', 'gip12345'))
          .thenAnswer((_) async => carmen);

      final activo = await servicio.iniciarSesion(
        '  Carmen@GIP.test ',
        'gip12345',
      );

      expect(activo.usuario.getNombre(), 'Carmen');
      expect(activo.usuario, isA<Administrador>());
      expect(activo.tienda.getId(), '11111111-1111-4111-8111-111111111111');
      verify(() => sesionLocal.guardar(carmen)).called(1);
    });

    test('rechaza al usuario desactivado y cierra la sesión', () async {
      final UsuarioActivo inactivo = (
        usuario: Empleado('3333', 'Luis', '1000000002', activo: false),
        tienda: tienda,
      );
      when(() => autenticacion.iniciarSesion(any(), any()))
          .thenAnswer((_) async => inactivo);

      await expectLater(
        servicio.iniciarSesion('luis@gip.test', 'gip12345'),
        throwsA(isA<ExcepcionUsuarioInactivo>()),
      );
      verify(() => autenticacion.cerrarSesion()).called(1);
      verifyNever(() => sesionLocal.guardar(any()));
    });
  });

  group('sesionGuardada', () {
    test('devuelve el usuario guardado si hay sesión', () async {
      when(() => autenticacion.haySesionGuardada()).thenReturn(true);
      when(() => sesionLocal.leer()).thenAnswer((_) async => carmen);

      expect(await servicio.sesionGuardada(), carmen);
    });

    test('devuelve null y limpia el dispositivo si no hay sesión', () async {
      when(() => autenticacion.haySesionGuardada()).thenReturn(false);

      expect(await servicio.sesionGuardada(), isNull);
      verify(() => sesionLocal.borrar()).called(1);
      verifyNever(() => sesionLocal.leer());
    });
  });

  test('cerrarSesion borra el usuario guardado y la sesión', () async {
    await servicio.cerrarSesion();

    verify(() => sesionLocal.borrar()).called(1);
    verify(() => autenticacion.cerrarSesion()).called(1);
  });

  group('exigirPropietario', () {
    test('deja pasar al administrador', () {
      servicio.exigirPropietario(carmen.usuario);
    });

    test('rechaza al empleado', () {
      expect(
        () => servicio.exigirPropietario(Empleado('3333', 'Luis', '1')),
        throwsA(isA<ExcepcionSoloPropietario>()),
      );
    });
  });
}
