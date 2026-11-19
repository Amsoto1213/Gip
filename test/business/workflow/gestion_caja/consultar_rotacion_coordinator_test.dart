import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_reportes.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/gestion_caja/rotacion.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_inventario_repositorio.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/business/workflow/gestion_caja/consultar_rotacion_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';

import '../../componentes/gestion_caja/fakes_caja.dart';
import '../../componentes/pagos/fakes_pagos.dart';

class MovimientosFalsos extends Mock
    implements IMovimientoInventarioRepositorio {}

class InventarioFalso extends Mock implements IInventarioRepositorio {}

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

/// CUS-12: solo el propietario consulta la rotación (RNF-12).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final desde = DateTime.utc(2026, 10, 21);
  final hasta = DateTime.utc(2026, 11, 20);
  Decimal d(String v) => Decimal.parse(v);

  late MovimientosFalsos movimientos;
  late InventarioFalso inventario;
  late ConsultarRotacionCoordinator coordinador;

  setUpAll(() {
    registerFallbackValue(tienda);
    registerFallbackValue(desde);
  });

  setUp(() {
    movimientos = MovimientosFalsos();
    inventario = InventarioFalso();
    coordinador = ConsultarRotacionCoordinator(
      ServicioReportes(
        VentaRepositorioFalso(),
        movimientos,
        CajaRepositorioFalso(),
        FiadoRepositorioFalso(),
        EstadoSincronizacionFalso(),
        inventario,
      ),
      ServicioAcceso(AutenticacionFalsa(), SesionLocalFalsa()),
    );
  });

  test('el propietario recibe la rotación por producto', () async {
    final huevo = ItemInventario(
      'i1',
      Producto('p1', 'H1', 'Huevo AA', UnidadMedida.unidad, d('400'), d('550')),
      d('10'),
    );
    final velas = ItemInventario(
      'i2',
      Producto('p2', 'V1', 'Velas', UnidadMedida.unidad, d('300'), d('500')),
      d('4'),
    );
    final fecha = DateTime.utc(2026, 11, 6);
    when(() => inventario.listarItems(tienda))
        .thenAnswer((_) async => [huevo, velas]);
    when(() => movimientos.listarSalidasPorTienda(tienda, desde, hasta))
        .thenAnswer(
          (_) async => [
            SalidaVenta(
              's1',
              huevo,
              d('-2'),
              fecha,
              Venta('v1', const [], d('1100'), fecha),
              d('550'),
              d('400'),
            ),
          ],
        );

    final rotacion = await coordinador.consultarRotacion(
      tienda,
      desde,
      hasta,
      Administrador('2222', 'Carmen', '1000000001'),
    );

    expect(
      {for (final e in rotacion.entries) e.key.getId(): e.value},
      {'p1': Rotacion.alta, 'p2': Rotacion.baja},
    );
  });

  test('el empleado no consulta: acceso denegado y no se lee nada', () async {
    await expectLater(
      coordinador.consultarRotacion(
        tienda,
        desde,
        hasta,
        Empleado('3333', 'Luis', '1'),
      ),
      throwsA(isA<ExcepcionSoloPropietario>()),
    );
    verifyNever(() => inventario.listarItems(any()));
    verifyNever(() => movimientos.listarSalidasPorTienda(any(), any(), any()));
  });
}
