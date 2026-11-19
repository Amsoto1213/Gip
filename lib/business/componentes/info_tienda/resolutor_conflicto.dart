import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Polymorphism y Protected Variations: cada tipo de conflicto se resuelve a su
/// manera. Un tipo nuevo es una clase nueva, sin modificar
/// `ServicioConciliacion` (OCP, DA-66).
abstract interface class ResolutorConflicto {
  /// Indica si este resolutor atiende ese tipo de conflicto.
  bool admite(ConflictoSincronizacion conflicto);

  /// Aplica la decisión del propietario; [idsElegidos] son los registros que
  /// el propietario escogió (puede ir vacío). Lo que significa "escogido"
  /// depende del tipo: a qué registros se les aplica la decisión (DI-45).
  /// `ServicioConciliacion` lo llama dentro de una transacción.
  Future<void> resolver(
    Tienda tienda,
    ConflictoSincronizacion conflicto,
    List<String> idsElegidos,
  );
}
