import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/data/repositorios/info_tienda/mapeo_usuario.dart';
import 'package:gip/transversal/errores/errores_usuarios.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Filas de `usuarios` y errores del servidor (CUS-15, DI-42).
void main() {
  final tienda = Tienda('t-uuid', 'T001', 'Granero El Porvenir', 'Arjona');

  group('aEntidad', () {
    test('ADMINISTRADOR es el propietario', () {
      final u = MapeoUsuario.aEntidad({
        'id': 'u1',
        'nombre': 'Carmen Ruiz',
        'cedula': '1000000001',
        'rol': 'ADMINISTRADOR',
        'activo': true,
      });

      expect(u, isA<Administrador>());
      expect(u.getId(), 'u1');
      expect(u.getNombre(), 'Carmen Ruiz');
      expect(u.getCedula(), '1000000001');
      expect(u.isActivo(), isTrue);
    });

    test('EMPLEADO inactivo', () {
      final u = MapeoUsuario.aEntidad({
        'id': 'u2',
        'nombre': 'Ana Torres',
        'cedula': '1000000003',
        'rol': 'EMPLEADO',
        'activo': false,
      });

      expect(u, isA<Empleado>());
      expect(u.isActivo(), isFalse);
    });

    test('sin el valor de activo, queda activo', () {
      final u = MapeoUsuario.aEntidad({
        'id': 'u2',
        'nombre': 'Luis',
        'cedula': '2',
        'rol': 'EMPLEADO',
        'activo': null,
      });

      expect(u.isActivo(), isTrue);
    });

    test('un rol desconocido se rechaza', () {
      expect(
        () => MapeoUsuario.aEntidad({
          'id': 'u3',
          'nombre': 'X',
          'cedula': '3',
          'rol': 'SUPERVISOR',
          'activo': true,
        }),
        throwsFormatException,
      );
    });

    test('las columnas que se piden no incluyen el correo', () {
      expect(MapeoUsuario.columnas, isNot(contains('correo')));
    });
  });

  group('aFila', () {
    final ahora = DateTime.utc(2026, 11, 19, 15, 30);

    test('empleado nuevo: tienda, rol y activo; sin correo', () {
      final fila = MapeoUsuario.aFila(
        tienda,
        Empleado('u2', 'Daniel Mendoza', '1045678901'),
        ahora: ahora,
      );

      expect(fila, {
        'id': 'u2',
        'tienda_id': 't-uuid',
        'nombre': 'Daniel Mendoza',
        'cedula': '1045678901',
        'rol': 'EMPLEADO',
        'activo': true,
        'actualizado_en': '2026-11-19T15:30:00.000Z',
      });
      // Sin correo: al actualizar no se borra el que ya tiene.
      expect(fila.containsKey('correo'), isFalse);
    });

    test('empleado desactivado va con activo falso', () {
      final fila = MapeoUsuario.aFila(
        tienda,
        Empleado('u2', 'Luis', '2')..desactivar(),
        ahora: ahora,
      );

      expect(fila['activo'], isFalse);
    });

    test('el propietario va con rol ADMINISTRADOR', () {
      final fila = MapeoUsuario.aFila(
        tienda,
        Administrador('u1', 'Carmen', '1'),
        ahora: ahora,
      );

      expect(fila['rol'], 'ADMINISTRADOR');
    });

    test('actualizado_en va en UTC aunque la hora sea local', () {
      final local = DateTime(2026, 11, 19, 10);
      final fila = MapeoUsuario.aFila(
        tienda,
        Empleado('u2', 'Luis', '2'),
        ahora: local,
      );

      final fecha = DateTime.parse(fila['actualizado_en'] as String);
      expect(fecha.isUtc, isTrue);
      expect(fecha.isAtSameMomentAs(local), isTrue);
    });

    test('lo que se guarda se vuelve a leer igual', () {
      final original = Empleado('u2', 'Ana Torres', '3')..desactivar();

      final leido = MapeoUsuario.aEntidad(
        MapeoUsuario.aFila(tienda, original, ahora: ahora),
      );

      expect(leido, isA<Empleado>());
      expect(leido.getId(), 'u2');
      expect(leido.getNombre(), 'Ana Torres');
      expect(leido.getCedula(), '3');
      expect(leido.isActivo(), isFalse);
    });
  });

  group('traducirError', () {
    test('cédula repetida en la tienda (23505): datos no válidos', () {
      final error = MapeoUsuario.traducirError(
        const PostgrestException(
          message: 'duplicate key value violates unique constraint',
          code: '23505',
        ),
      );

      expect(error, isA<ExcepcionDatosUsuarioNoValidos>());
    });

    test('otro error del servidor llega tal cual', () {
      const original = PostgrestException(message: 'permiso', code: '42501');

      expect(MapeoUsuario.traducirError(original), same(original));
    });

    test('una falla de red es "Necesitas internet…"', () {
      final error = MapeoUsuario.traducirError(Exception('SocketException'));

      expect(error, isA<ExcepcionSinConexionUsuarios>());
      expect(
        (error as ExcepcionSinConexionUsuarios).mensaje,
        'Necesitas internet para ver y cambiar los usuarios',
      );
    });
  });
}
