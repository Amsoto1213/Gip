import 'package:gip/business/entidades/gestion_inventario/etiqueta.dart';

/// Protected Variations: genera el PDF de etiquetas y lo envía a imprimir. La
/// implementación va fuera de la Business Layer (DA-39, DI-35).
abstract interface class IImpresionEtiquetas {
  /// Arma las etiquetas en hojas adhesivas tamaño carta y abre la impresión.
  Future<void> imprimir(List<Etiqueta> etiquetas);
}
