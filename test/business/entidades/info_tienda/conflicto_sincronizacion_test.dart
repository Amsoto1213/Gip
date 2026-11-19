import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';

/// ConflictoSincronizacion (CUS-22, DA-48, DI-45).
void main() {
  final fecha = DateTime.utc(2026, 11, 19, 15, 45);

  ConflictoSincronizacion crear({List<String>? etiquetas}) =>
      ConflictoSincronizacion(
        'POSIBLE_DUPLICADO:m1:m2',
        TipoConflicto.posibleDuplicado,
        'Dos entradas iguales de huevos con la factura FV-10231',
        ['m1', 'm2'],
        fecha,
        etiquetasRegistros: etiquetas,
      );

  test('guarda lo que recibe y nace sin resolver', () {
    final c = crear(etiquetas: ['Entrada A', 'Entrada B']);

    expect(c.getId(), 'POSIBLE_DUPLICADO:m1:m2');
    expect(c.getTipo(), TipoConflicto.posibleDuplicado);
    expect(
      c.getDescripcion(),
      'Dos entradas iguales de huevos con la factura FV-10231',
    );
    expect(c.getIdsRegistros(), ['m1', 'm2']);
    expect(c.getEtiquetasRegistros(), ['Entrada A', 'Entrada B']);
    expect(c.getFecha(), fecha);
    expect(c.isResuelto(), isFalse);
  });

  test('setResuelto lo marca y lo desmarca', () {
    final c = crear()..setResuelto(true);
    expect(c.isResuelto(), isTrue);

    c.setResuelto(false);
    expect(c.isResuelto(), isFalse);
  });

  test('se puede armar uno ya resuelto (leído de la base)', () {
    final c = ConflictoSincronizacion(
      'x',
      TipoConflicto.stockNegativo,
      'd',
      ['m1'],
      fecha,
      resuelto: true,
    );

    expect(c.isResuelto(), isTrue);
  });

  group('etiquetas de los registros (DI-45)', () {
    test('sin etiquetas, cada registro se llama "Registro N"', () {
      expect(crear().getEtiquetasRegistros(), ['Registro 1', 'Registro 2']);
    });

    test('getEtiquetaDe busca por id y es nula si no es del conflicto', () {
      final c = crear(etiquetas: ['Entrada A', 'Entrada B']);

      expect(c.getEtiquetaDe('m2'), 'Entrada B');
      expect(c.getEtiquetaDe('otro'), isNull);
    });

    test('con distinto número de etiquetas que de registros, se rechaza', () {
      expect(() => crear(etiquetas: ['solo una']), throwsArgumentError);
      expect(() => crear(etiquetas: ['a', 'b', 'c']), throwsArgumentError);
    });
  });

  test('las listas que devuelve no se pueden modificar', () {
    final c = crear(etiquetas: ['a', 'b']);

    expect(() => c.getIdsRegistros().add('m3'), throwsUnsupportedError);
    expect(() => c.getEtiquetasRegistros().add('c'), throwsUnsupportedError);
  });

  test('copia la lista de ids: cambiar la original no lo cambia', () {
    final ids = ['m1', 'm2'];
    final c = ConflictoSincronizacion(
      'x',
      TipoConflicto.posibleDuplicado,
      'd',
      ids,
      fecha,
    );

    ids.add('m3');

    expect(c.getIdsRegistros(), ['m1', 'm2']);
  });

  test('hay cinco tipos de conflicto', () {
    expect(TipoConflicto.values, hasLength(5));
  });
}
