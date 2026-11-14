import 'package:gip/business/entidades/gestion_inventario/etiqueta.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_impresion_etiquetas.dart';

/// Relleno hasta la iteración 4 (DI-15): `ServicioCatalogo` la recibe en su
/// constructor, pero ningún flujo actual imprime etiquetas.
class ImpresionEtiquetasPendiente implements IImpresionEtiquetas {
  const ImpresionEtiquetasPendiente();

  @override
  Future<void> imprimir(List<Etiqueta> etiquetas) => throw UnimplementedError(
    'Imprimir etiquetas no está disponible todavía (DI-15)',
  );
}
