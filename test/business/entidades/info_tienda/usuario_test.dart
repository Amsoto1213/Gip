import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';

void main() {
  test('desactivar deja al usuario inactivo', () {
    final luis = Empleado('3333', 'Luis', '1000000002');

    luis.desactivar();

    expect(luis.isActivo(), isFalse);
  });

  test('desactivar rechaza a un usuario ya inactivo', () {
    final luis = Empleado('3333', 'Luis', '1000000002', activo: false);

    expect(luis.desactivar, throwsA(isA<ExcepcionUsuarioYaInactivo>()));
  });
}
