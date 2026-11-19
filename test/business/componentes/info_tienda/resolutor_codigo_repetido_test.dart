import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_codigo_repetido.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/transversal/errores/errores_conciliacion.dart';

import '../gestion_inventario/fakes_catalogo.dart';

/// ResolutorCodigoRepetido (CUS-22, DA-66, DI-45): el propietario escoge qué
/// productos pierden el código repetido.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);

  late ProductoRepositorioFalso productos;
  late ResolutorCodigoRepetido resolutor;

  setUp(() {
    productos = ProductoRepositorioFalso();
    resolutor = ResolutorCodigoRepetido(productos);
  });

  Producto producto(
    String id,
    String codigo, {
    List<(String, String)> barras = const [],
  }) {
    final p = Producto(
      id,
      codigo,
      'Producto $id',
      UnidadMedida.unidad,
      d('1000'),
      d('1500'),
    );
    for (final (idCodigo, valor) in barras) {
      p.agregarCodigo(CodigoProducto(idCodigo, FormatoCodigo.ean13, valor));
    }
    return p;
  }

  Future<void> guardar(List<Producto> lista) async {
    for (final p in lista) {
      await productos.guardar(tienda, p);
    }
    productos.guardadosEnTransaccion.clear();
  }

  ConflictoSincronizacion conflicto(List<String> ids) =>
      ConflictoSincronizacion(
        'CODIGO_REPETIDO:${ids.join(':')}',
        TipoConflicto.codigoRepetido,
        'Dos productos tienen el mismo código',
        ids,
        DateTime.utc(2026, 11, 19),
      );

  test('admite solo código repetido', () {
    for (final tipo in TipoConflicto.values) {
      expect(
        resolutor.admite(
          ConflictoSincronizacion('x', tipo, 'd', ['p1'], DateTime.utc(2026)),
        ),
        tipo == TipoConflicto.codigoRepetido,
        reason: '$tipo',
      );
    }
  });

  group('código de barras o QR repetido', () {
    test(
      'al producto elegido se le quita el código; el otro lo conserva',
      () async {
        final p1 = producto('p1', 'A-1', barras: [('c1', '7701234567895')]);
        final p2 = producto('p2', 'B-1', barras: [('c2', '7701234567895')]);
        await guardar([p1, p2]);

        await resolutor.resolver(tienda, conflicto(['p1', 'p2']), ['p2']);

        expect(p2.getCodigos(), isEmpty);
        expect(p1.getCodigos().map((c) => c.getValor()), ['7701234567895']);
        expect(productos.codigosQuitados, [('p2', 'c2')]);
      },
    );

    test('solo quita el código compartido: los demás códigos del producto '
        'siguen', () async {
      final p1 = producto('p1', 'A-1', barras: [('c1', '7701234567895')]);
      final p2 = producto(
        'p2',
        'B-1',
        barras: [('c2', '7701234567895'), ('c3', '7709999999999')],
      );
      await guardar([p1, p2]);

      await resolutor.resolver(tienda, conflicto(['p1', 'p2']), ['p2']);

      expect(p2.getCodigos().map((c) => c.getValor()), ['7709999999999']);
      expect(productos.codigosQuitados, [('p2', 'c2')]);
    });

    test('si se eligen los dos, los dos pierden el código', () async {
      final p1 = producto('p1', 'A-1', barras: [('c1', '7701234567895')]);
      final p2 = producto('p2', 'B-1', barras: [('c2', '7701234567895')]);
      await guardar([p1, p2]);

      await resolutor.resolver(tienda, conflicto(['p1', 'p2']), ['p1', 'p2']);

      expect(p1.getCodigos(), isEmpty);
      expect(p2.getCodigos(), isEmpty);
      expect(productos.codigosQuitados, [('p1', 'c1'), ('p2', 'c2')]);
    });

    test('cuenta el valor repetido por el texto exacto del código', () async {
      final p1 = producto('p1', 'A-1', barras: [('c1', 'QR-123')]);
      final p2 = producto('p2', 'B-1', barras: [('c2', 'qr-123')]);
      await guardar([p1, p2]);

      // "QR-123" y "qr-123" son lecturas distintas (DA-41): no se repiten.
      await resolutor.resolver(tienda, conflicto(['p1', 'p2']), ['p2']);

      expect(productos.codigosQuitados, isEmpty);
      expect(p2.getCodigos(), hasLength(1));
    });
  });

  group('código interno repetido', () {
    test('al producto elegido se le cambia a "codigo-2"', () async {
      final p1 = producto('p1', 'GAL-6');
      final p2 = producto('p2', 'GAL-6');
      await guardar([p1, p2]);

      await resolutor.resolver(tienda, conflicto(['p1', 'p2']), ['p2']);

      expect(p2.getCodigo(), 'GAL-6-2');
      expect(p1.getCodigo(), 'GAL-6');
      expect(
        (await productos.buscarPorId(tienda, 'p2'))!.getCodigo(),
        'GAL-6-2',
      );
    });

    test('si "codigo-2" ya existe, usa "codigo-3"', () async {
      final p1 = producto('p1', 'GAL-6');
      final p2 = producto('p2', 'GAL-6');
      final otro = producto('p3', 'GAL-6-2');
      await guardar([p1, p2, otro]);

      await resolutor.resolver(tienda, conflicto(['p1', 'p2']), ['p2']);

      expect(p2.getCodigo(), 'GAL-6-3');
    });

    test(
      'si se eligen los dos, cada uno queda con un código distinto',
      () async {
        final p1 = producto('p1', 'GAL-6');
        final p2 = producto('p2', 'GAL-6');
        await guardar([p1, p2]);

        await resolutor.resolver(tienda, conflicto(['p1', 'p2']), ['p1', 'p2']);

        expect({p1.getCodigo(), p2.getCodigo()}, {'GAL-6-2', 'GAL-6-3'});
      },
    );

    test('guarda el producto con productos.guardar y sube su fecha de edición '
        '(gana la edición más reciente, DA-48)', () async {
      final p1 = producto('p1', 'GAL-6');
      final p2 = producto('p2', 'GAL-6');
      await guardar([p1, p2]);
      final antes = p2.getActualizadoEn();

      await resolutor.resolver(tienda, conflicto(['p1', 'p2']), ['p2']);

      expect(p2.getActualizadoEn().isBefore(antes), isFalse);
      expect(p2.getActualizadoEn().isUtc, isTrue);
      expect(productos.guardadosEnTransaccion, hasLength(1));
    });

    test('los códigos de barras del producto no se tocan si solo se repite el '
        'interno', () async {
      final p1 = producto('p1', 'GAL-6', barras: [('c1', '7701111111116')]);
      final p2 = producto('p2', 'GAL-6', barras: [('c2', '7702222222229')]);
      await guardar([p1, p2]);

      await resolutor.resolver(tienda, conflicto(['p1', 'p2']), ['p2']);

      expect(p2.getCodigos(), hasLength(1));
      expect(productos.codigosQuitados, isEmpty);
    });
  });

  group('los dos tipos de repetido a la vez', () {
    test('quita el código de barras y cambia el interno', () async {
      final p1 = producto('p1', 'GAL-6', barras: [('c1', '7701234567895')]);
      final p2 = producto('p2', 'GAL-6', barras: [('c2', '7701234567895')]);
      await guardar([p1, p2]);

      await resolutor.resolver(tienda, conflicto(['p1', 'p2']), ['p2']);

      expect(p2.getCodigos(), isEmpty);
      expect(p2.getCodigo(), 'GAL-6-2');
      expect(p1.getCodigos(), hasLength(1));
      expect(p1.getCodigo(), 'GAL-6');
    });
  });

  group('lo que no se debe tocar', () {
    test('un producto elegido que no comparte nada (ya se corrigió en otro '
        'equipo) no cambia', () async {
      final p1 = producto('p1', 'A-1', barras: [('c1', '7701111111116')]);
      final p2 = producto('p2', 'B-1', barras: [('c2', '7702222222229')]);
      await guardar([p1, p2]);

      await resolutor.resolver(tienda, conflicto(['p1', 'p2']), ['p2']);

      expect(p2.getCodigos(), hasLength(1));
      expect(p2.getCodigo(), 'B-1');
      expect(productos.codigosQuitados, isEmpty);
      expect(productos.guardadosEnTransaccion, isEmpty);
    });

    test('los productos que no se eligieron no cambian', () async {
      final p1 = producto('p1', 'GAL-6', barras: [('c1', '7701234567895')]);
      final p2 = producto('p2', 'GAL-6', barras: [('c2', '7701234567895')]);
      final p3 = producto('p3', 'GAL-6', barras: [('c3', '7701234567895')]);
      await guardar([p1, p2, p3]);

      await resolutor.resolver(tienda, conflicto(['p1', 'p2', 'p3']), ['p3']);

      expect(p1.getCodigos(), hasLength(1));
      expect(p2.getCodigos(), hasLength(1));
      expect(p3.getCodigos(), isEmpty);
    });
  });

  group('errores', () {
    test('sin elegir ningún producto: hay que marcar al menos uno', () async {
      final p1 = producto('p1', 'GAL-6');
      final p2 = producto('p2', 'GAL-6');
      await guardar([p1, p2]);

      await expectLater(
        resolutor.resolver(tienda, conflicto(['p1', 'p2']), const []),
        throwsA(
          isA<ExcepcionDecisionIncompleta>().having(
            (e) => e.mensaje,
            'mensaje',
            'Marque los productos que pierden el código repetido',
          ),
        ),
      );
      expect(p1.getCodigo(), 'GAL-6');
      expect(p2.getCodigo(), 'GAL-6');
    });

    test(
      'un id elegido que no es del conflicto cuenta como no elegir nada',
      () async {
        final p1 = producto('p1', 'GAL-6');
        final p2 = producto('p2', 'GAL-6');
        await guardar([p1, p2]);

        await expectLater(
          resolutor.resolver(tienda, conflicto(['p1', 'p2']), ['p9']),
          throwsA(isA<ExcepcionDecisionIncompleta>()),
        );
      },
    );

    test(
      'si falta algún producto del conflicto: error y no cambia nada',
      () async {
        final p1 = producto('p1', 'GAL-6');
        await guardar([p1]);

        await expectLater(
          resolutor.resolver(tienda, conflicto(['p1', 'p2']), ['p1']),
          throwsA(isA<ExcepcionRegistrosDelConflictoNoEncontrados>()),
        );
        expect(p1.getCodigo(), 'GAL-6');
      },
    );

    test('si guardar falla, el error llega', () async {
      final p1 = producto('p1', 'GAL-6');
      final p2 = producto('p2', 'GAL-6');
      await guardar([p1, p2]);
      productos.fallar = true;

      await expectLater(
        resolutor.resolver(tienda, conflicto(['p1', 'p2']), ['p2']),
        throwsA(isA<StateError>()),
      );
    });
  });
}
