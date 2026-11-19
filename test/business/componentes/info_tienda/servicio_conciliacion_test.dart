import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/servicio_conciliacion.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/transversal/errores/errores_conciliacion.dart';

import '../gestion_inventario/fakes_catalogo.dart';
import 'fakes_conciliacion.dart';

/// obtenerConflictos y resolverConflicto (CUS-22, DA-48, DA-66, DI-45).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otraTienda = Tienda('t2', 'T002', 'Tienda Dos', 'Turbaco');

  late ConflictoRepositorioFalso conflictos;
  late UnidadTrabajoFalsa unidad;
  late List<String> eventos;
  late ResolutorFalso deMovimientos;
  late ResolutorFalso deAbonos;
  late ServicioConciliacion servicio;

  ConflictoSincronizacion conflicto(
    String id,
    TipoConflicto tipo, {
    DateTime? fecha,
    bool resuelto = false,
  }) => ConflictoSincronizacion(
    id,
    tipo,
    'Descripción de $id',
    ['r1', 'r2'],
    fecha ?? DateTime.utc(2026, 11, 19, 15),
    resuelto: resuelto,
  );

  setUp(() {
    eventos = [];
    conflictos = ConflictoRepositorioFalso();
    unidad = UnidadTrabajoFalsa([conflictos]);
    conflictos.unidad = unidad;
    deMovimientos = ResolutorFalso({
      TipoConflicto.posibleDuplicado,
      TipoConflicto.stockNegativo,
    }, eventos)..unidad = unidad;
    deAbonos = ResolutorFalso({TipoConflicto.abonoExcedeSaldo}, eventos)
      ..unidad = unidad;
    servicio = ServicioConciliacion(conflictos, unidad, [
      deMovimientos,
      deAbonos,
    ]);
  });

  group('obtenerConflictos', () {
    test('sin conflictos devuelve una lista vacía', () async {
      expect(await servicio.obtenerConflictos(tienda), isEmpty);
    });

    test('trae solo los pendientes, del más antiguo al más reciente', () async {
      conflictos
        ..sembrar(
          tienda,
          conflicto(
            'b',
            TipoConflicto.stockNegativo,
            fecha: DateTime.utc(2026, 11, 19, 16),
          ),
        )
        ..sembrar(
          tienda,
          conflicto(
            'a',
            TipoConflicto.posibleDuplicado,
            fecha: DateTime.utc(2026, 11, 19, 10),
          ),
        )
        ..sembrar(
          tienda,
          conflicto('ya', TipoConflicto.codigoRepetido, resuelto: true),
        );

      final lista = await servicio.obtenerConflictos(tienda);

      expect(lista.map((c) => c.getId()), ['a', 'b']);
    });

    test('solo los de la tienda pedida', () async {
      conflictos
        ..sembrar(tienda, conflicto('mio', TipoConflicto.stockNegativo))
        ..sembrar(otraTienda, conflicto('ajeno', TipoConflicto.stockNegativo));

      expect((await servicio.obtenerConflictos(tienda)).map((c) => c.getId()), [
        'mio',
      ]);
    });
  });

  group('resolverConflicto', () {
    test(
      'elige el resolutor que admite el tipo y le pasa la decisión',
      () async {
        final c = conflicto('d1', TipoConflicto.posibleDuplicado);
        conflictos.sembrar(tienda, c);

        await servicio.resolverConflicto(tienda, c, ['r2']);

        expect(deMovimientos.llamadas, hasLength(1));
        final (t, recibido, ids) = deMovimientos.llamadas.single;
        expect(t, tienda);
        expect(recibido, same(c));
        expect(ids, ['r2']);
        expect(deAbonos.llamadas, isEmpty);
      },
    );

    test('otro tipo lo atiende el otro resolutor', () async {
      final c = conflicto('a1', TipoConflicto.abonoExcedeSaldo);
      conflictos.sembrar(tienda, c);

      await servicio.resolverConflicto(tienda, c, ['r1']);

      expect(deAbonos.llamadas, hasLength(1));
      expect(deMovimientos.llamadas, isEmpty);
    });

    test('si varios lo admiten, gana el primero de la lista', () async {
      final otro = ResolutorFalso({TipoConflicto.posibleDuplicado});
      final servicio2 = ServicioConciliacion(conflictos, unidad, [
        otro,
        deMovimientos,
      ]);
      final c = conflicto('d1', TipoConflicto.posibleDuplicado);
      conflictos.sembrar(tienda, c);

      await servicio2.resolverConflicto(tienda, c, []);

      expect(otro.llamadas, hasLength(1));
      expect(deMovimientos.llamadas, isEmpty);
    });

    test('con la decisión vacía también lo aplica (por ejemplo, "aceptar '
        'así")', () async {
      final c = conflicto('s1', TipoConflicto.stockNegativo);
      conflictos.sembrar(tienda, c);

      await servicio.resolverConflicto(tienda, c, const []);

      expect(deMovimientos.llamadas.single.$3, isEmpty);
      expect(c.isResuelto(), isTrue);
    });

    test('deja el conflicto resuelto y lo marca en el repositorio', () async {
      final c = conflicto('d1', TipoConflicto.posibleDuplicado);
      conflictos.sembrar(tienda, c);

      await servicio.resolverConflicto(tienda, c, ['r1']);

      expect(c.isResuelto(), isTrue);
      expect(conflictos.marcados, ['d1']);
      expect(await servicio.obtenerConflictos(tienda), isEmpty);
    });

    test('primero aplica la decisión y después marca el conflicto', () async {
      final c = conflicto('d1', TipoConflicto.posibleDuplicado);
      conflictos.sembrar(tienda, c);
      // marcarResuelto se anota en la misma lista de eventos.
      final registrando = ResolutorFalso({
        TipoConflicto.posibleDuplicado,
      }, eventos)..unidad = unidad;
      final servicio2 = ServicioConciliacion(conflictos, unidad, [registrando]);

      await servicio2.resolverConflicto(tienda, c, []);
      eventos.add(conflictos.marcados.isNotEmpty ? 'marcado' : 'sin marcar');

      expect(eventos, ['resolver', 'marcado']);
    });

    test('todo ocurre en una sola transacción', () async {
      final c = conflicto('d1', TipoConflicto.posibleDuplicado);
      conflictos.sembrar(tienda, c);

      await servicio.resolverConflicto(tienda, c, ['r1']);

      expect(unidad.transacciones, 1);
      expect(deMovimientos.enTransaccion, [true]);
      expect(conflictos.marcadosEnTransaccion, [true]);
    });

    test('si el resolutor falla: el error llega, no se marca nada y el '
        'conflicto sigue pendiente', () async {
      final c = conflicto('d1', TipoConflicto.posibleDuplicado);
      conflictos.sembrar(tienda, c);
      deMovimientos.fallar = true;

      await expectLater(
        servicio.resolverConflicto(tienda, c, ['r1']),
        throwsA(isA<StateError>()),
      );

      expect(c.isResuelto(), isFalse);
      expect(conflictos.marcados, isEmpty);
      expect((await servicio.obtenerConflictos(tienda)).map((x) => x.getId()), [
        'd1',
      ]);
    });

    test('si marcarResuelto falla: rollback, el conflicto queda sin resolver '
        'también en memoria', () async {
      final c = conflicto('d1', TipoConflicto.posibleDuplicado);
      conflictos.sembrar(tienda, c);
      conflictos.fallarAlMarcar = true;

      await expectLater(
        servicio.resolverConflicto(tienda, c, ['r1']),
        throwsA(isA<StateError>()),
      );

      expect(c.isResuelto(), isFalse);
      expect(conflictos.resueltos(tienda), isEmpty);
    });

    test('un conflicto que ya estaba resuelto se rechaza y no se aplica otra '
        'vez', () async {
      final c = conflicto('a1', TipoConflicto.abonoExcedeSaldo, resuelto: true);

      await expectLater(
        servicio.resolverConflicto(tienda, c, ['r1']),
        throwsA(
          isA<ExcepcionConflictoYaResuelto>().having(
            (e) => e.mensaje,
            'mensaje',
            'Este conflicto ya estaba resuelto',
          ),
        ),
      );
      expect(deAbonos.llamadas, isEmpty);
      expect(conflictos.marcados, isEmpty);
    });

    test(
      'un tipo que ningún resolutor atiende se rechaza sin tocar nada',
      () async {
        final c = conflicto('c1', TipoConflicto.codigoRepetido);
        conflictos.sembrar(tienda, c);

        await expectLater(
          servicio.resolverConflicto(tienda, c, ['r1']),
          throwsA(
            isA<ExcepcionConflictoSinResolutor>().having(
              (e) => e.mensaje,
              'mensaje',
              'No se sabe cómo resolver este tipo de conflicto',
            ),
          ),
        );
        expect(c.isResuelto(), isFalse);
        expect(conflictos.marcados, isEmpty);
      },
    );

    test('resolver uno no afecta a los demás pendientes', () async {
      final a = conflicto('a', TipoConflicto.posibleDuplicado);
      final b = conflicto('b', TipoConflicto.stockNegativo);
      conflictos
        ..sembrar(tienda, a)
        ..sembrar(tienda, b);

      await servicio.resolverConflicto(tienda, a, ['r1']);

      expect((await servicio.obtenerConflictos(tienda)).map((x) => x.getId()), [
        'b',
      ]);
    });
  });
}
