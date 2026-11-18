import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/business/workflow/gestion_caja/registrar_cierre_caja_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/errores_caja.dart';
import 'package:mocktail/mocktail.dart';

import '../../componentes/gestion_caja/fakes_caja.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

/// CUS-14: solo el propietario consulta el saldo esperado y cierra la caja
/// (RNF-12).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final propietario = Administrador('2222', 'Carmen', '1000000001');
  Decimal d(String v) => Decimal.parse(v);

  late CajaRepositorioFalso cajas;
  late ServicioCaja servicioCaja;
  late RegistrarCierreCajaCoordinator coordinador;

  setUp(() {
    cajas = CajaRepositorioFalso();
    servicioCaja = ServicioCaja(cajas);
    coordinador = RegistrarCierreCajaCoordinator(
      servicioCaja,
      ServicioAcceso(AutenticacionFalsa(), SesionLocalFalsa()),
    );
  });

  test('el propietario consulta el saldo esperado', () async {
    await servicioCaja.registrarIngreso(tienda, d('318500'), 'Venta');

    expect(
      await coordinador.consultarSaldoEsperado(tienda, propietario),
      d('318500'),
    );
  });

  test('el propietario cierra la caja y recibe el faltante', () async {
    await servicioCaja.registrarIngreso(tienda, d('318500'), 'Venta');

    final diferencia = await coordinador.cerrarCaja(
      tienda,
      d('315000'),
      propietario,
    );

    expect(diferencia, d('-3500'));
    expect(cajas.cierres[tienda.getId()], hasLength(1));
  });

  test('el empleado no consulta ni cierra: acceso denegado', () async {
    final empleado = Empleado('3333', 'Luis', '1');

    await expectLater(
      coordinador.consultarSaldoEsperado(tienda, empleado),
      throwsA(isA<ExcepcionSoloPropietario>()),
    );
    await expectLater(
      coordinador.cerrarCaja(tienda, d('1'), empleado),
      throwsA(isA<ExcepcionSoloPropietario>()),
    );
    expect(cajas.cajas, isEmpty);
    expect(cajas.cierres, isEmpty);
  });

  test('un segundo cierre llega como caja cerrada', () async {
    await coordinador.cerrarCaja(tienda, d('0'), propietario);

    await expectLater(
      coordinador.cerrarCaja(tienda, d('0'), propietario),
      throwsA(isA<ExcepcionCajaCerrada>()),
    );
  });
}
