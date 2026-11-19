/// Tipos de choque que requieren revisión del propietario (DA-48): los
/// detecta la conciliación al sincronizar (CUS-23) y los resuelve CUS-22.
enum TipoConflicto {
  /// Después de unir los registros, un ítem quedó con existencia negativa.
  stockNegativo,

  /// Los abonos de un fiado suman más que lo que se debía.
  abonoExcedeSaldo,

  /// Un código (de barras, QR o interno) quedó en dos productos.
  codigoRepetido,

  /// Dos entradas de mercancía iguales (mismo ítem, cantidad y factura).
  posibleDuplicado,

  /// Un movimiento llegó a una caja que ya estaba cerrada.
  movimientoCajaCerrada,
}
