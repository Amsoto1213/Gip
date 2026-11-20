import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/presentation/negocio/agrupar_conflictos.dart';

void main() {
  final fecha = DateTime.utc(2026, 11, 20, 15);
  ConflictoSincronizacion c(String id, TipoConflicto tipo, List<String> ids) =>
      ConflictoSincronizacion(id, tipo, 'x', ids, fecha);

  List<List<String>> ids(List<List<ConflictoSincronizacion>> grupos) => [
    for (final g in grupos) [for (final x in g) x.getId()],
  ];

  test('sin conflictos no hay grupos', () {
    expect(agruparConflictos(const []), isEmpty);
  });

  test('una pareja es un grupo de uno', () {
    final grupos = agruparConflictos([
      c('d1', TipoConflicto.posibleDuplicado, ['e0', 'e1']),
    ]);

    expect(ids(grupos), [
      ['d1'],
    ]);
  });

  test('las parejas que comparten la entrada original son un solo grupo', () {
    final grupos = agruparConflictos([
      c('d1', TipoConflicto.posibleDuplicado, ['e0', 'e1']),
      c('d2', TipoConflicto.posibleDuplicado, ['e0', 'e2']),
    ]);

    expect(ids(grupos), [
      ['d1', 'd2'],
    ]);
  });

  test('parejas de otras entradas originales son otro grupo', () {
    final grupos = agruparConflictos([
      c('d1', TipoConflicto.posibleDuplicado, ['e0', 'e1']),
      c('d2', TipoConflicto.posibleDuplicado, ['x0', 'x1']),
      c('d3', TipoConflicto.posibleDuplicado, ['e0', 'e2']),
    ]);

    expect(ids(grupos), [
      ['d1', 'd3'],
      ['d2'],
    ]);
  });

  test('los demás tipos nunca se juntan, ni con los mismos registros', () {
    final grupos = agruparConflictos([
      c('s1', TipoConflicto.stockNegativo, ['m1', 'm2']),
      c('s2', TipoConflicto.stockNegativo, ['m1', 'm2']),
      c('k1', TipoConflicto.codigoRepetido, ['p1', 'p2']),
      c('d1', TipoConflicto.posibleDuplicado, ['p1', 'p2']),
    ]);

    expect(ids(grupos), [
      ['s1'],
      ['s2'],
      ['k1'],
      ['d1'],
    ]);
  });

  test('un conflicto sin registros no rompe la agrupación', () {
    final grupos = agruparConflictos([
      c('d0', TipoConflicto.posibleDuplicado, const []),
    ]);

    expect(ids(grupos), [
      ['d0'],
    ]);
  });
}
