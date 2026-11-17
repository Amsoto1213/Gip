import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/consultar_existencias_coordinator.dart';
import 'package:mocktail/mocktail.dart';

class ServicioInventarioFalso extends Mock implements ServicioInventario {}

/// CUS-25: el coordinador solo delega en ServicioInventario.
void main() {
  final tienda = Tienda(
    '11111111-1111-4111-8111-111111111111',
    'T001',
    'Granero El Porvenir',
    'Arjona, Bolívar',
  );
  final huevo = Producto(
    '22222222-2222-4222-8222-222222222222',
    'HUE-1',
    'Huevo AA',
    UnidadMedida.unidad,
    null,
    Decimal.parse('700'),
  );
  final desde = DateTime.utc(2026, 11, 1);
  final hasta = DateTime.utc(2026, 11, 8);

  late ServicioInventarioFalso servicio;
  late ConsultarExistenciasCoordinator coordinador;

  setUp(() {
    servicio = ServicioInventarioFalso();
    coordinador = ConsultarExistenciasCoordinator(servicio);
  });

  test('listarExistencias delega en el servicio', () async {
    final items = [ItemInventario('i1', huevo, Decimal.parse('90'))];
    when(() => servicio.listarExistencias(tienda))
        .thenAnswer((_) async => items);

    expect(await coordinador.listarExistencias(tienda), same(items));
    verify(() => servicio.listarExistencias(tienda)).called(1);
    verifyNoMoreInteractions(servicio);
  });

  test('consultarMovimientos delega en el servicio con el periodo', () async {
    final item = ItemInventario('i1', huevo, Decimal.parse('90'));
    final movimientos = [
      Merma('m1', item, Decimal.parse('-2'), desde, MotivoMerma.danado),
    ];
    when(() => servicio.consultarMovimientos(tienda, huevo, desde, hasta))
        .thenAnswer((_) async => movimientos);

    expect(
      await coordinador.consultarMovimientos(tienda, huevo, desde, hasta),
      same(movimientos),
    );
    verify(() => servicio.consultarMovimientos(tienda, huevo, desde, hasta))
        .called(1);
    verifyNoMoreInteractions(servicio);
  });
}
