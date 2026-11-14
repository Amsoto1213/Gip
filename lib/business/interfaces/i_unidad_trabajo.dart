/// Unidad de trabajo: ejecuta varias operaciones de distintos repositorios como
/// una sola transacción; si una falla, no se guarda ninguna (RNF-04, DA-44).
/// La Data Layer la implementa con una transacción de drift.
abstract interface class IUnidadTrabajo {
  /// Ejecuta [accion] dentro de una transacción: todo se guarda o nada se
  /// guarda. Si se llama dentro de otra ejecución (por ejemplo
  /// aplicarMovimiento dentro de confirmar), se une a la transacción de afuera:
  /// no abre otra ni guarda por separado (DA-53).
  Future<void> ejecutar(Future<void> Function() accion);
}
