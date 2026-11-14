import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_perdida_coordinator.dart';
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
  final leche = Producto(
    '22222222-2222-4222-8222-222222222222',
    'LEC-1',
    'Leche bolsa 1 L',
    UnidadMedida.unidad,
    null,
    Decimal.parse('4200'),
  );
  final dos = Decimal.fromInt(2);

  late ServicioInventarioFalso servicio;
  late RegistrarPerdidaCoordinator coordinador;

  setUp(() {
    servicio = ServicioInventarioFalso();
    coordinador = RegistrarPerdidaCoordinator(servicio);
  });

  test('consultarExistencia devuelve el stock del ítem', () async {
    when(
      () => servicio.obtenerItem(tienda, leche),
    ).thenAnswer((_) async => ItemInventario('i1', leche, Decimal.fromInt(14)));

    expect(
      await coordinador.consultarExistencia(tienda, leche),
      Decimal.fromInt(14),
    );
    verify(() => servicio.obtenerItem(tienda, leche)).called(1);
    verifyNoMoreInteractions(servicio);
  });

  test(
    'registrarPerdida delega en registrarMerma y devuelve la merma',
    () async {
      final merma = Merma(
        'm1',
        ItemInventario('i1', leche, Decimal.fromInt(12)),
        -dos,
        DateTime.utc(2026, 11, 14),
        MotivoMerma.vencido,
      );
      when(
        () => servicio.registrarMerma(tienda, leche, dos, MotivoMerma.vencido),
      ).thenAnswer((_) async => merma);

      expect(
        await coordinador.registrarPerdida(
          tienda,
          leche,
          dos,
          MotivoMerma.vencido,
        ),
        same(merma),
      );
      verify(
        () => servicio.registrarMerma(tienda, leche, dos, MotivoMerma.vencido),
      ).called(1);
      verifyNoMoreInteractions(servicio);
    },
  );

  test('registrarPerdida deja pasar el error del servicio', () async {
    when(() => servicio.registrarMerma(tienda, leche, dos, null))
        .thenAnswer((_) async => throw const ExcepcionDatosMermaNoValidos());

    await expectLater(
      coordinador.registrarPerdida(tienda, leche, dos, null),
      throwsA(isA<ExcepcionDatosMermaNoValidos>()),
    );
  });
}
