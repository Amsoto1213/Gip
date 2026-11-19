import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/info_tienda/conflicto_repositorio_drift.dart';

/// ConflictoRepositorioDrift (CUS-22, DA-33, DA-48, DI-45).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otra = Tienda('t2', 'T002', 'Otra tienda', 'Turbaco');

  late BaseLocalDrift base;
  late ConflictoRepositorioDrift repositorio;

  setUp(() {
    base = BaseLocalDrift(NativeDatabase.memory());
    repositorio = ConflictoRepositorioDrift(base);
  });
  tearDown(() => base.close());

  ConflictoSincronizacion conflicto(
    String id, {
    TipoConflicto tipo = TipoConflicto.posibleDuplicado,
    DateTime? fecha,
    List<String> ids = const ['m1', 'm2'],
    List<String>? etiquetas,
    bool resuelto = false,
  }) => ConflictoSincronizacion(
    id,
    tipo,
    'Descripción de $id',
    ids,
    fecha ?? DateTime.utc(2026, 11, 19, 15, 45),
    etiquetasRegistros: etiquetas,
    resuelto: resuelto,
  );

  Future<List<Map<String, Object?>>> cola() async => [
    for (final f in await base.select(base.colaPendientes).get())
      {'tabla': f.tabla, 'id': f.registroId, 'op': f.operacion},
  ];

  group('guardar y listarPendientes', () {
    test('guarda el conflicto y lo vuelve a leer completo', () async {
      await repositorio.guardar(
        tienda,
        conflicto(
          'POSIBLE_DUPLICADO:m1:m2',
          ids: ['m1', 'm2'],
          etiquetas: ['Entrada de las 10:42', 'Entrada de las 10:43'],
        ),
      );

      final lista = await repositorio.listarPendientes(tienda);

      expect(lista, hasLength(1));
      final c = lista.single;
      expect(c.getId(), 'POSIBLE_DUPLICADO:m1:m2');
      expect(c.getTipo(), TipoConflicto.posibleDuplicado);
      expect(c.getDescripcion(), 'Descripción de POSIBLE_DUPLICADO:m1:m2');
      expect(c.getIdsRegistros(), ['m1', 'm2']);
      expect(c.getEtiquetasRegistros(), [
        'Entrada de las 10:42',
        'Entrada de las 10:43',
      ]);
      expect(c.getFecha(), DateTime.utc(2026, 11, 19, 15, 45));
      expect(c.getFecha().isUtc, isTrue);
      expect(c.isResuelto(), isFalse);
    });

    test('guarda y lee los cinco tipos', () async {
      for (final (i, tipo) in TipoConflicto.values.indexed) {
        await repositorio.guardar(tienda, conflicto('c$i', tipo: tipo));
      }

      final lista = await repositorio.listarPendientes(tienda);

      expect(
        lista.map((c) => c.getTipo()).toSet(),
        TipoConflicto.values.toSet(),
      );
    });

    test('los ids con comas, comillas o tildes no rompen la lista', () async {
      await repositorio.guardar(
        tienda,
        conflicto(
          'x',
          ids: ['a,b', 'c"d'],
          etiquetas: ['Café, "grande"', 'Ñandú\nnuevo'],
        ),
      );

      final c = (await repositorio.listarPendientes(tienda)).single;

      expect(c.getIdsRegistros(), ['a,b', 'c"d']);
      expect(c.getEtiquetasRegistros(), ['Café, "grande"', 'Ñandú\nnuevo']);
    });

    test('sin etiquetas, quedan las de "Registro N"', () async {
      await repositorio.guardar(tienda, conflicto('x'));

      final c = (await repositorio.listarPendientes(tienda)).single;

      expect(c.getEtiquetasRegistros(), ['Registro 1', 'Registro 2']);
    });

    test('guardar el mismo id dos veces no lo duplica ni anota dos veces en '
        'la cola (dos equipos pueden detectar el mismo choque)', () async {
      await repositorio.guardar(tienda, conflicto('mismo'));
      await repositorio.guardar(tienda, conflicto('mismo'));

      expect(await repositorio.listarPendientes(tienda), hasLength(1));
      expect(await cola(), [
        {'tabla': 'conflictos_sincronizacion', 'id': 'mismo', 'op': 'INSERTAR'},
      ]);
    });

    test('si el conflicto ya estaba resuelto, guardarlo otra vez no lo '
        'reabre', () async {
      await repositorio.guardar(tienda, conflicto('mismo'));
      await repositorio.marcarResuelto(tienda, conflicto('mismo'));

      await repositorio.guardar(tienda, conflicto('mismo'));

      expect(await repositorio.listarPendientes(tienda), isEmpty);
    });

    test('solo trae los de la tienda y los pendientes, del más antiguo al más '
        'reciente', () async {
      await repositorio.guardar(
        tienda,
        conflicto('tarde', fecha: DateTime.utc(2026, 11, 19, 18)),
      );
      await repositorio.guardar(
        tienda,
        conflicto('temprano', fecha: DateTime.utc(2026, 11, 19, 9)),
      );
      await repositorio.guardar(otra, conflicto('ajeno'));
      await repositorio.guardar(tienda, conflicto('resuelto'));
      await repositorio.marcarResuelto(tienda, conflicto('resuelto'));

      final lista = await repositorio.listarPendientes(tienda);

      expect(lista.map((c) => c.getId()), ['temprano', 'tarde']);
    });

    test('una tienda sin conflictos devuelve una lista vacía', () async {
      expect(await repositorio.listarPendientes(tienda), isEmpty);
    });

    test('anota el INSERTAR en la cola de pendientes', () async {
      await repositorio.guardar(tienda, conflicto('c1'));

      expect(await cola(), [
        {'tabla': 'conflictos_sincronizacion', 'id': 'c1', 'op': 'INSERTAR'},
      ]);
    });
  });

  group('marcarResuelto', () {
    test('lo saca de los pendientes y anota el ACTUALIZAR', () async {
      await repositorio.guardar(tienda, conflicto('c1'));
      await repositorio.guardar(tienda, conflicto('c2'));
      await base.delete(base.colaPendientes).go();

      await repositorio.marcarResuelto(tienda, conflicto('c1'));

      expect(
        (await repositorio.listarPendientes(tienda)).map((c) => c.getId()),
        ['c2'],
      );
      expect(await cola(), [
        {'tabla': 'conflictos_sincronizacion', 'id': 'c1', 'op': 'ACTUALIZAR'},
      ]);
    });

    test('no cambia lo demás del conflicto', () async {
      await repositorio.guardar(tienda, conflicto('c1', etiquetas: ['a', 'b']));

      await repositorio.marcarResuelto(tienda, conflicto('c1'));

      final fila = await base.select(base.conflictosSincronizacion).getSingle();
      expect(fila.resuelto, isTrue);
      expect(fila.descripcion, 'Descripción de c1');
      expect(fila.idsRegistros, '["m1","m2"]');
      expect(fila.etiquetasRegistros, '["a","b"]');
    });

    test('con la tienda equivocada no cambia nada', () async {
      await repositorio.guardar(tienda, conflicto('c1'));

      await repositorio.marcarResuelto(otra, conflicto('c1'));

      expect(await repositorio.listarPendientes(tienda), hasLength(1));
    });
  });
}
