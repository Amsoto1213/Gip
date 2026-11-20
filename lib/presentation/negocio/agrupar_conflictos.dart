import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';

/// Junta los conflictos que son una sola situación para el tendero (DI-51).
///
/// Cuando una misma entrada se registra varias veces (tres equipos, o dos
/// equipos y una anterior), la conciliación guarda un conflicto POSIBLE_DUPLICADO
/// por cada repetida, cada uno con la entrada original y una repetida
/// (DI-46 e). Aquí se juntan los que comparten la entrada original: la pantalla
/// muestra una sola tarjeta con todas las entradas y la decisión se aplica a
/// cada conflicto de la tarjeta. Los demás conflictos van solos.
///
/// Conserva el orden de la lista: cada grupo queda donde estaba su primer
/// conflicto, y dentro del grupo el orden original.
List<List<ConflictoSincronizacion>> agruparConflictos(
  List<ConflictoSincronizacion> conflictos,
) {
  final grupos = <List<ConflictoSincronizacion>>[];
  final porOriginal = <String, List<ConflictoSincronizacion>>{};
  for (final c in conflictos) {
    if (c.getTipo() == TipoConflicto.posibleDuplicado &&
        c.getIdsRegistros().isNotEmpty) {
      final original = c.getIdsRegistros().first;
      final existente = porOriginal[original];
      if (existente != null) {
        existente.add(c);
        continue;
      }
      final nuevo = [c];
      porOriginal[original] = nuevo;
      grupos.add(nuevo);
    } else {
      grupos.add([c]);
    }
  }
  return grupos;
}
