import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_entrada_mercancia_coordinator.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';
import 'package:mocktail/mocktail.dart';

class ServicioInventarioFalso extends Mock implements ServicioInventario {}

void main() {
  final tienda = Tienda(
    '11111111-1111-4111-8111-111111111111',
    'T001',
    'Granero El Porvenir',
    'Arjona, Bolívar',
  );
  final aceite = Producto(
    '22222222-2222-4222-8222-222222222222',
    'ACE-1',
    'Aceite 1 L',
    UnidadMedida.unidad,
    null,
    Decimal.parse('11000'),
  );
  final costo = Decimal.parse('9400');
  final cantidad = Decimal.parse('24');

  late ServicioInventarioFalso servicio;
  late RegistrarEntradaMercanciaCoordinator coordinador;

  setUp(() {
    servicio = ServicioInventarioFalso();
    coordinador = RegistrarEntradaMercanciaCoordinator(servicio);
  });

  test('verificarCosto delega en costoDifiereDelHistorico', () async {
    when(() => servicio.costoDifiereDelHistorico(tienda, aceite, costo))
        .thenAnswer((_) async => true);

    expect(await coordinador.verificarCosto(tienda, aceite, costo), isTrue);
    verify(() => servicio.costoDifiereDelHistorico(tienda, aceite, costo))
        .called(1);
    verifyNoMoreInteractions(servicio);
  });

  test('registrarEntrada delega y devuelve la entrada', () async {
    final entrada = EntradaMercancia(
      'e1',
      ItemInventario('i1', aceite, Decimal.parse('32')),
      cantidad,
      DateTime.utc(2026, 11, 14),
      costo,
      'FV-1',
    );
    when(
      () => servicio.registrarEntrada(tienda, aceite, cantidad, costo, 'FV-1'),
    ).thenAnswer((_) async => entrada);

    final resultado = await coordinador.registrarEntrada(
      tienda,
      aceite,
      cantidad,
      costo,
      'FV-1',
    );

    expect(resultado, same(entrada));
    expect(resultado.getItem().getStockActual(), Decimal.parse('32'));
    verify(
      () => servicio.registrarEntrada(tienda, aceite, cantidad, costo, 'FV-1'),
    ).called(1);
    verifyNoMoreInteractions(servicio);
  });

  test('registrarEntrada deja pasar el error del servicio', () async {
    when(() => servicio.registrarEntrada(tienda, aceite, cantidad, costo, null))
        .thenAnswer((_) async => throw const ExcepcionDatosEntradaNoValidos());

    await expectLater(
      coordinador.registrarEntrada(tienda, aceite, cantidad, costo, null),
      throwsA(isA<ExcepcionDatosEntradaNoValidos>()),
    );
  });
}
