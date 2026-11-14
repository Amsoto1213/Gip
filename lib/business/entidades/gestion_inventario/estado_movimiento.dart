/// Estado de un movimiento de inventario para la conciliación (DA-48). Solo
/// los VIGENTES suman al stock; EN_REVISION y ANULADO no (ERS 3.2.1 c).
enum EstadoMovimiento { vigente, enRevision, anulado }
