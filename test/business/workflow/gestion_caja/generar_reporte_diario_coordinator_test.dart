import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_reportes.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/business/workflow/gestion_caja/generar_reporte_diario_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';

import '../../componentes/gestion_caja/fakes_caja.dart';
import '../../componentes/gestion_inventario/fakes_inventario.dart';
import '../../componentes/pagos/fakes_pagos.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

/// CUS-10: solo el propietario genera el reporte diario (RNF-12).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final dia = DateTime(2026, 11, 14);

  late VentaRepositorioFalso ventas;
  late GenerarReporteDiarioCoordinator coordinador;

  setUp(() {
    ventas = VentaRepositorioFalso();
    coordinador = GenerarReporteDiarioCoordinator(
      ServicioReportes(
        ventas,
        MovimientoRepositorioFalso(),
        CajaRepositorioFalso(),
        FiadoRepositorioFalso(),
        EstadoSincronizacionFalso(),
      ),
      ServicioAcceso(AutenticacionFalsa(), SesionLocalFalsa()),
    );
  });

  test('el propietario recibe el reporte del día', () async {
    await ventas.guardar(
      tienda,
      Venta(
        'v1',
        [PagoContado('p1', Decimal.parse('5000'), Decimal.zero)],
        Decimal.parse('5000'),
        DateTime(2026, 11, 14, 10),
      ),
    );

    final reporte = await coordinador.generarReporte(
      tienda,
      dia,
      Administrador('2222', 'Carmen', '1000000001'),
    );

    expect(reporte.getTotalVentas(), Decimal.parse('5000'));
  });

  test('el empleado no genera el reporte: acceso denegado', () async {
    await expectLater(
      coordinador.generarReporte(tienda, dia, Empleado('3333', 'Luis', '1')),
      throwsA(isA<ExcepcionSoloPropietario>()),
    );
  });
}
