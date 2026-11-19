import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/info_tienda/servicio_exportacion.dart';
import 'package:gip/business/entidades/info_tienda/formato_exportacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_inventario_repositorio.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/business/interfaces/pagos/i_fiado_repositorio.dart';
import 'package:gip/business/interfaces/pagos/i_venta_repositorio.dart';
import 'package:gip/business/workflow/info_tienda/exportar_datos_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/errores_exportacion.dart';
import 'package:mocktail/mocktail.dart';

import '../../componentes/info_tienda/fakes_exportacion.dart';

class InventarioFalso extends Mock implements IInventarioRepositorio {}

class VentasFalsas extends Mock implements IVentaRepositorio {}

class FiadosFalsos extends Mock implements IFiadoRepositorio {}

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

/// CUS-16: solo el propietario exporta los datos del negocio (RNF-12).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final desde = DateTime.utc(2026, 10, 1);
  final hasta = DateTime.utc(2026, 11, 1);

  late InventarioFalso inventario;
  late VentasFalsas ventas;
  late FiadosFalsos fiados;
  late ExportadorFalso exportador;
  late ExportarDatosCoordinator coordinador;

  setUpAll(() {
    registerFallbackValue(tienda);
    registerFallbackValue(desde);
  });

  setUp(() {
    inventario = InventarioFalso();
    ventas = VentasFalsas();
    fiados = FiadosFalsos();
    exportador = ExportadorFalso();
    when(() => inventario.listarItems(any())).thenAnswer((_) async => []);
    when(() => ventas.listarPorPeriodo(any(), any(), any()))
        .thenAnswer((_) async => []);
    when(() => fiados.listar(any())).thenAnswer((_) async => []);
    coordinador = ExportarDatosCoordinator(
      ServicioExportacion(inventario, ventas, fiados, exportador),
      ServicioAcceso(AutenticacionFalsa(), SesionLocalFalsa()),
    );
  });

  test('el propietario recibe el nombre del archivo', () async {
    final nombre = await coordinador.exportar(
      tienda,
      desde,
      hasta,
      FormatoExportacion.excel,
      Administrador('2222', 'Carmen', '1000000001'),
    );

    expect(nombre, 'gip-prueba.xlsx');
    expect(exportador.recibidos, hasLength(1));
    verify(() => inventario.listarItems(tienda)).called(1);
    verify(() => ventas.listarPorPeriodo(tienda, desde, hasta)).called(1);
    verify(() => fiados.listar(tienda)).called(1);
  });

  test('el empleado no exporta: acceso denegado y no se lee nada', () async {
    await expectLater(
      coordinador.exportar(
        tienda,
        desde,
        hasta,
        FormatoExportacion.excel,
        Empleado('3333', 'Luis', '1'),
      ),
      throwsA(isA<ExcepcionSoloPropietario>()),
    );

    verifyNever(() => inventario.listarItems(any()));
    verifyNever(() => ventas.listarPorPeriodo(any(), any(), any()));
    verifyNever(() => fiados.listar(any()));
    expect(exportador.recibidos, isEmpty);
  });

  test('el periodo no válido llega como error de negocio', () async {
    await expectLater(
      coordinador.exportar(
        tienda,
        hasta,
        desde,
        FormatoExportacion.csv,
        Administrador('2222', 'Carmen', '1000000001'),
      ),
      throwsA(isA<ExcepcionPeriodoNoValido>()),
    );
    expect(exportador.recibidos, isEmpty);
  });
}
