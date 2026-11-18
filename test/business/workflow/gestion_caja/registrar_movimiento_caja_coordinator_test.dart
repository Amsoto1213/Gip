import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/business/workflow/gestion_caja/registrar_movimiento_caja_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/errores_caja.dart';
import 'package:mocktail/mocktail.dart';

import '../../componentes/gestion_caja/fakes_caja.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

/// CUS-11: solo el propietario anota movimientos de caja (RNF-12).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final propietario = Administrador('2222', 'Carmen', '1000000001');

  late CajaRepositorioFalso cajas;
  late RegistrarMovimientoCajaCoordinator coordinador;

  setUp(() {
    cajas = CajaRepositorioFalso();
    coordinador = RegistrarMovimientoCajaCoordinator(
      ServicioCaja(cajas),
      ServicioAcceso(AutenticacionFalsa(), SesionLocalFalsa()),
    );
  });

  Future<dynamic> anotar(
    usuario, {
    ClasificacionMovimiento clasificacion = ClasificacionMovimiento.personal,
    String valor = '40000',
  }) => coordinador.registrarMovimiento(
    tienda,
    TipoMovimientoCaja.egreso,
    clasificacion,
    Decimal.parse(valor),
    'Retiro',
    usuario,
  );

  test('el propietario anota el movimiento y queda guardado', () async {
    final mov = await anotar(propietario);

    expect(mov.getDescripcion(), 'Retiro');
    expect(cajas.movimientosDe(tienda), [mov]);
  });

  test('el empleado no anota nada: acceso denegado', () async {
    await expectLater(
      anotar(Empleado('3333', 'Luis', '1')),
      throwsA(isA<ExcepcionSoloPropietario>()),
    );
    expect(cajas.cajas, isEmpty);
    expect(cajas.movimientos, isEmpty);
  });

  test('los errores del servicio llegan sin cambios', () async {
    await expectLater(
      anotar(propietario, clasificacion: ClasificacionMovimiento.anulacion),
      throwsA(isA<ExcepcionClasificacionNoPermitida>()),
    );
    await expectLater(
      anotar(propietario, valor: '0'),
      throwsA(isA<ExcepcionValorMovimientoNoValido>()),
    );
  });
}
