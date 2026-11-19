import 'package:flutter_test/flutter_test.dart';
import 'package:gip/data/service_agents/mapeo_cuenta_acceso.dart';
import 'package:gip/transversal/errores/errores_usuarios.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Errores de Supabase Auth al crear la cuenta de un empleado (CUS-15, DI-43).
void main() {
  group('cuentaYaExiste', () {
    test('por código', () {
      for (final code in ['user_already_exists', 'email_exists']) {
        expect(
          MapeoCuentaAcceso.cuentaYaExiste(
            AuthApiException('x', statusCode: '422', code: code),
          ),
          isTrue,
          reason: code,
        );
      }
    });

    test('por texto, si el servidor no manda código', () {
      expect(
        MapeoCuentaAcceso.cuentaYaExiste(
          const AuthApiException('User already registered', statusCode: '422'),
        ),
        isTrue,
      );
    });

    test('otros errores no son "ya existe"', () {
      expect(
        MapeoCuentaAcceso.cuentaYaExiste(
          const AuthApiException('x', statusCode: '400', code: 'weak_password'),
        ),
        isFalse,
      );
      expect(
        MapeoCuentaAcceso.cuentaYaExiste(
          const AuthApiException('User already registered', statusCode: '400'),
        ),
        isFalse,
      );
    });
  });

  group('credencialesNoCoinciden', () {
    test('por código y por texto', () {
      expect(
        MapeoCuentaAcceso.credencialesNoCoinciden(
          const AuthApiException('x', code: 'invalid_credentials'),
        ),
        isTrue,
      );
      expect(
        MapeoCuentaAcceso.credencialesNoCoinciden(
          const AuthApiException('Invalid login credentials'),
        ),
        isTrue,
      );
      expect(
        MapeoCuentaAcceso.credencialesNoCoinciden(
          const AuthApiException('otra cosa', code: 'over_request_rate_limit'),
        ),
        isFalse,
      );
    });
  });

  group('traducirError', () {
    test('contraseña débil: contraseña no válida, con el mínimo de la '
        'configuración', () {
      final error = MapeoCuentaAcceso.traducirError(
        const AuthApiException('x', code: 'weak_password'),
      );

      expect(error, isA<ExcepcionClaveNoValida>());
      expect(
        (error as ExcepcionClaveNoValida).mensaje,
        'La contraseña debe tener al menos 6 caracteres',
      );
    });

    test('la cuenta ya existe: correo ya registrado', () {
      expect(
        MapeoCuentaAcceso.traducirError(
          const AuthApiException('x', statusCode: '422', code: 'email_exists'),
        ),
        isA<ExcepcionCorreoYaRegistrado>(),
      );
    });

    test('sin respuesta del servidor: "Necesitas internet…"', () {
      expect(
        MapeoCuentaAcceso.traducirError(
          AuthRetryableFetchException(message: 'sin red'),
        ),
        isA<ExcepcionSinConexionUsuarios>(),
      );
      expect(
        MapeoCuentaAcceso.traducirError(Exception('SocketException')),
        isA<ExcepcionSinConexionUsuarios>(),
      );
    });

    test('otro rechazo de Auth (por ejemplo, registros desactivados): no se '
        'pudo crear la cuenta', () {
      expect(
        MapeoCuentaAcceso.traducirError(
          const AuthApiException(
            'Signups not allowed',
            statusCode: '422',
            code: 'signup_disabled',
          ),
        ),
        isA<ExcepcionCuentaNoCreada>(),
      );
    });

    test('un error de negocio ya traducido se deja tal cual', () {
      const original = ExcepcionCorreoYaRegistrado();

      expect(MapeoCuentaAcceso.traducirError(original), same(original));
    });
  });
}
