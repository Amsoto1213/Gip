/// Indirection, Protected Variations y DIP: contrato de acceso al historial de
/// movimientos de inventario; la Data Layer lo implementa (RNF-08).
///
/// Sin operaciones por ahora (DI-15): las agrega CUS-01 junto con
/// `MovimientoInventario` y sus subclases. Existe para respetar el constructor
/// de `ServicioInventario` de EA.
abstract interface class IMovimientoInventarioRepositorio {}
