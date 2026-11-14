import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';

void main() {
  late BaseLocalDrift base;
  late UnidadTrabajoDrift unidadTrabajo;

  setUp(() {
    base = BaseLocalDrift(NativeDatabase.memory());
    unidadTrabajo = UnidadTrabajoDrift(base);
  });

  tearDown(() => base.close());

  Future<void> encolar(String id) => base
      .into(base.colaPendientes)
      .insert(
        ColaPendientesCompanion.insert(
          id: id,
          tiendaId: 't1',
          tabla: 'productos',
          registroId: 'p-$id',
          operacion: 'INSERTAR',
          creadoEn: DateTime.utc(2026, 11, 14),
        ),
      );

  Future<List<String>> idsGuardados() async =>
      (await base.select(base.colaPendientes).get()).map((e) => e.id).toList();

  test('si la acción termina bien, se guarda todo', () async {
    await unidadTrabajo.ejecutar(() async {
      await encolar('a');
      await encolar('b');
    });

    expect(await idsGuardados(), unorderedEquals(['a', 'b']));
  });

  test(
    'si la acción lanza un error, no se guarda nada y el error sube',
    () async {
      final ejecucion = unidadTrabajo.ejecutar(() async {
        await encolar('a');
        throw StateError('falla a mitad');
      });

      await expectLater(ejecucion, throwsStateError);
      expect(await idsGuardados(), isEmpty);
    },
  );

  test('una ejecución anidada se une a la de afuera', () async {
    await unidadTrabajo.ejecutar(() async {
      await encolar('afuera');
      await unidadTrabajo.ejecutar(() => encolar('adentro'));
    });

    expect(await idsGuardados(), unorderedEquals(['afuera', 'adentro']));
  });

  test(
    'si la acción anidada lanza un error, se deshace también lo de afuera',
    () async {
      final ejecucion = unidadTrabajo.ejecutar(() async {
        await encolar('afuera');
        await unidadTrabajo.ejecutar(() async {
          await encolar('adentro');
          throw StateError('falla adentro');
        });
      });

      await expectLater(ejecucion, throwsStateError);
      expect(await idsGuardados(), isEmpty);
    },
  );

  test('si falla la de afuera después de la anidada, no queda nada', () async {
    final ejecucion = unidadTrabajo.ejecutar(() async {
      await unidadTrabajo.ejecutar(() => encolar('adentro'));
      await encolar('afuera');
      throw StateError('falla afuera');
    });

    await expectLater(ejecucion, throwsStateError);
    expect(await idsGuardados(), isEmpty);
  });
}
