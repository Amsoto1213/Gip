import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/ajuste_conteo.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_conteo_coordinator.dart';
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
  final huevo = Producto(
    '22222222-2222-4222-8222-222222222222',
    'HUE-1',
    'Huevo AA',
    UnidadMedida.unidad,
    null,
    Decimal.parse('700'),
  );
  Decimal d(String v) => Decimal.parse(v);

  late ServicioInventarioFalso servicio;
  late RegistrarConteoCoordinator coordinador;

  setUp(() {
    servicio = ServicioInventarioFalso();
    coordinador = RegistrarConteoCoordinator(servicio);
  });

  test('listarExistencias delega en el servicio', () async {
    final items = [ItemInventario('i1', huevo, d('90'))];
    when(() => servicio.listarExistencias(tienda))
        .thenAnswer((_) async => items);

    expect(await coordinador.listarExistencias(tienda), same(items));
    verify(() => servicio.listarExistencias(tienda)).called(1);
    verifyNoMoreInteractions(servicio);
  });

  test('calcularDiferencia delega en el servicio', () async {
    when(() => servicio.calcularDiferencia(tienda, huevo, d('78')))
        .thenAnswer((_) async => d('-12'));

    expect(
      await coordinador.calcularDiferencia(tienda, huevo, d('78')),
      d('-12'),
    );
  });

  test('requiereRevision devuelve lo del servicio', () {
    when(() => servicio.requiereRevision(d('-12'))).thenReturn(true);
    when(() => servicio.requiereRevision(d('1'))).thenReturn(false);

    expect(coordinador.requiereRevision(d('-12')), isTrue);
    expect(coordinador.requiereRevision(d('1')), isFalse);
  });

  test(
    'confirmarAjuste llama a registrarConteo y devuelve el ajuste',
    () async {
      final ajuste = AjusteConteo(
        'a1',
        ItemInventario('i1', huevo, d('78')),
        d('-12'),
        DateTime.utc(2026, 11, 14),
        d('78'),
      );
      when(() => servicio.registrarConteo(tienda, huevo, d('78')))
          .thenAnswer((_) async => ajuste);

      expect(
        await coordinador.confirmarAjuste(tienda, huevo, d('78')),
        same(ajuste),
      );
      verify(() => servicio.registrarConteo(tienda, huevo, d('78'))).called(1);
    },
  );

  test('confirmarAjuste deja pasar el error del servicio', () async {
    when(
      () => servicio.registrarConteo(tienda, huevo, d('-1')),
    ).thenAnswer((_) async => throw const ExcepcionCantidadContadaNegativa());

    await expectLater(
      coordinador.confirmarAjuste(tienda, huevo, d('-1')),
      throwsA(isA<ExcepcionCantidadContadaNegativa>()),
    );
  });
}
