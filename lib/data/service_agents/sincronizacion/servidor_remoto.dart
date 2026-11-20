/// Una fila tal como viaja entre la app y el servidor: columnas en snake_case
/// y valores JSON (texto, número, booleano, lista o nulo).
typedef FilaRemota = Map<String, Object?>;

/// No hubo conexión o el servicio no respondió: se puede reintentar más tarde
/// sin perder nada. El Sincronizador se detiene y deja la cola como estaba.
class FalloDeRed implements Exception {
  const FalloDeRed([this.detalle = '']);

  final String detalle;

  @override
  String toString() => 'FalloDeRed($detalle)';
}

/// El servidor recibió la fila pero la rechazó (llave foránea, regla de la
/// tabla, columna desconocida). Reintentarla igual no sirve; el Sincronizador
/// la deja en la cola, cuenta el intento y sigue con las demás.
class RechazoDelServidor implements Exception {
  const RechazoDelServidor(this.detalle, [this.codigo]);

  final String detalle;
  final String? codigo;

  @override
  String toString() => 'RechazoDelServidor($codigo: $detalle)';
}

/// Lo único que el Sincronizador necesita del servidor (Protected Variations:
/// la Data Layer cambia de Supabase a un servidor falso en las pruebas sin
/// tocar el algoritmo, DI-47). Toda fila lleva `tienda_id` (RNF-13).
abstract interface class ServidorRemoto {
  /// Agrega las filas que no existan; las que ya existen no se tocan. Es lo
  /// que se usa con los registros de solo agregar (RNF-15).
  Future<void> insertarSiNoExiste(String tabla, List<FilaRemota> filas);

  /// Agrega las filas o actualiza las que ya existen (por `id`). Las reglas de
  /// choque las aplica el servidor (disparadores, DA-48).
  Future<void> guardar(String tabla, List<FilaRemota> filas);

  /// Borra la fila con ese `id`. No falla si ya no existe.
  Future<void> borrar(String tabla, String id);

  /// Filas de la tienda con `sincronizado_en` igual o posterior a [desde]
  /// (todas si es nulo), ordenadas por `sincronizado_en` y `id`: [limite]
  /// filas a partir de [desplazamiento]. Cada fila trae `sincronizado_en`.
  Future<List<FilaRemota>> leerDesde(
    String tabla,
    String tiendaId, {
    required String? desde,
    required int limite,
    required int desplazamiento,
  });
}
