import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_reportes.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/business/workflow/gestion_caja/consultar_margen_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';

import '../../componentes/gestion_caja/fakes_caja.dart';
import '../../componentes/pagos/fakes_pagos.dart';

class MovimientosFalsos extends Mock
    implements IMovimientoInventarioRepositorio {}

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

/// CUS-09: solo el propietario consulta el margen (RNF-12).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final desde = DateTime.utc(2026, 11, 5);
  final hasta = DateTime.utc(2026, 11, 12);
  Decimal d(String v) => Decimal.parse(v);

  late MovimientosFalsos movimientos;
  late ConsultarMargenCoordinator coordinador;

  setUpAll(() {
    registerFallbackValue(tienda);
    registerFallbackValue(desde);
  });

  setUp(() {
    movimientos = MovimientosFalsos();
    coordinador = ConsultarMargenCoordinator(
      ServicioReportes(
        VentaRepositorioFalso(),
        movimientos,
        CajaRepositorioFalso(),
        FiadoRepositorioFalso(),
        EstadoSincronizacionFalso(),
      ),
      ServicioAcceso(AutenticacionFalsa(), SesionLocalFalsa()),
    );
  });

  test('el propietario recibe el margen por producto', () async {
    final item = ItemInventario(
      'i1',
      Producto('p1', 'H1', 'Huevo AA', UnidadMedida.unidad, d('400'), d('550')),
      d('10'),
    );
    final fecha = DateTime.utc(2026, 11, 6);
    when(() => movimientos.listarSalidasPorTienda(tienda, desde, hasta))
        .thenAnswer(
          (_) async => [
            SalidaVenta(
              's1',
              item,
              d('-2'),
              fecha,
              Venta('v1', const [], d('1100'), fecha),
              d('550'),
              d('400'),
            ),
          ],
        );

    final margenes = await coordinador.consultarMargen(
      tienda,
      desde,
      hasta,
      Administrador('2222', 'Carmen', '1000000001'),
    );

    expect(margenes.values.single, d('300'));
  });

  test('el empleado no consulta: acceso denegado y no se lee nada', () async {
    await expectLater(
      coordinador.consultarMargen(
        tienda,
        desde,
        hasta,
        Empleado('3333', 'Luis', '1'),
      ),
      throwsA(isA<ExcepcionSoloPropietario>()),
    );
    verifyNever(() => movimientos.listarSalidasPorTienda(any(), any(), any()));
  });
}
