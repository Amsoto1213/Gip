/// Clasificación de un producto por unidades vendidas en un periodo (RF-11).
/// No se guarda: se calcula en cada consulta (DA-40). La usa
/// `ServicioReportes.clasificarRotacion`.
enum Rotacion { alta, media, baja }
