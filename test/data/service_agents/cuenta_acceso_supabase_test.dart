import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gip/data/service_agents/cuenta_acceso_supabase.dart';
import 'package:gip/transversal/configuracion/configuracion_supabase.dart';
import 'package:gip/transversal/errores/errores_usuarios.dart';

/// Crear la cuenta de un empleado con el cliente temporal **de verdad** (no un
/// doble): contra un servidor local que responde como Supabase Auth. Así se
/// prueba lo que la app arma por defecto, y no solo la traducción de errores.
void main() {
  late HttpServer servidor;
  late List<String> rutasPedidas;
  late int estado;
  late Map<String, Object?> respuesta;
  late bool claveCorrecta;

  setUp(() async {
    rutasPedidas = [];
    estado = 200;
    respuesta = _conSesion;
    claveCorrecta = true;
    servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servidor.listen((peticion) async {
      rutasPedidas.add('${peticion.method} ${peticion.uri.path}');
      await utf8.decoder.bind(peticion).join();
      // El inicio de sesión (/token) solo responde distinto en el caso de la
      // cuenta que ya existe con otra contraseña.
      final esInicio = peticion.uri.path.endsWith('/token');
      final rechazo = esInicio && !claveCorrecta;
      peticion.response
        ..statusCode = rechazo ? 400 : estado
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode(
            rechazo
                ? {
                    'code': 400,
                    'error_code': 'invalid_credentials',
                    'msg': 'Invalid login credentials',
                  }
                : respuesta,
          ),
        );
      await peticion.response.close();
    });
  });

  tearDown(() => servidor.close(force: true));

  CuentaAccesoSupabase cuentas() => CuentaAccesoSupabase(
    ConfiguracionSupabase(
      url: 'http://${servidor.address.host}:${servidor.port}',
      anonKey: 'llave-de-prueba',
    ),
  );

  test('crea la cuenta con el cliente temporal por defecto (sin almacenamiento '
      'para PKCE)', () async {
    await cuentas().crear('empleado@correo.com', 'Clave12345');

    expect(rutasPedidas, contains('POST /auth/v1/signup'));
  });

  test('si Supabase pide confirmar el correo (sin sesión), avisa que no se '
      'pudo crear la cuenta', () async {
    respuesta = {'id': 'u-1', 'email': 'empleado@correo.com'};

    await expectLater(
      cuentas().crear('empleado@correo.com', 'Clave12345'),
      throwsA(isA<ExcepcionCuentaNoCreada>()),
    );
  });

  test('si la cuenta ya existe con la misma clave (un intento anterior), '
      'sirve y no falla', () async {
    // El registro responde "ya existe"; el inicio de sesión acepta la clave.
    servidor.close(force: true);
    servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servidor.listen((peticion) async {
      rutasPedidas.add('${peticion.method} ${peticion.uri.path}');
      await utf8.decoder.bind(peticion).join();
      final esRegistro = peticion.uri.path.endsWith('/signup');
      peticion.response
        ..statusCode = esRegistro ? 422 : 200
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode(
            esRegistro
                ? {
                    'code': 422,
                    'error_code': 'user_already_exists',
                    'msg': 'User already registered',
                  }
                : _conSesion,
          ),
        );
      await peticion.response.close();
    });

    await cuentas().crear('empleado@correo.com', 'Clave12345');

    expect(rutasPedidas.take(2), [
      'POST /auth/v1/signup',
      'POST /auth/v1/token',
    ]);
  });

  test('si el correo ya tiene cuenta y la clave no coincide, es un correo ya '
      'registrado', () async {
    claveCorrecta = false;
    estado = 422;
    respuesta = {
      'code': 422,
      'error_code': 'user_already_exists',
      'msg': 'User already registered',
    };

    await expectLater(
      cuentas().crear('empleado@correo.com', 'Clave12345'),
      throwsA(isA<ExcepcionCorreoYaRegistrado>()),
    );
  });
}

const _conSesion = <String, Object?>{
  'access_token': 'token-de-acceso',
  'token_type': 'bearer',
  'expires_in': 3600,
  'refresh_token': 'token-de-renovacion',
  'user': {
    'id': '00000000-0000-4000-8000-000000000001',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'empleado@correo.com',
    'app_metadata': <String, Object?>{},
    'user_metadata': <String, Object?>{},
    'created_at': '2026-11-23T10:00:00Z',
  },
};
