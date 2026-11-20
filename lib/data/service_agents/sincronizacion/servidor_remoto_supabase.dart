import 'package:gip/data/service_agents/sincronizacion/servidor_remoto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [ServidorRemoto] sobre Supabase (PostgREST). Usa el cliente con la sesión
/// del dispositivo, ya iniciada (DI-05). Sin RLS: las tablas no tienen
/// políticas (`CLAUDE.md`), por eso todo filtro lleva `tienda_id`.
class ServidorRemotoSupabase implements ServidorRemoto {
  ServidorRemotoSupabase(this._cliente);

  final SupabaseClient _cliente;

  @override
  Future<void> insertarSiNoExiste(String tabla, List<FilaRemota> filas) =>
      _ejecutar(
        () => _cliente
            .from(tabla)
            .upsert(filas, onConflict: 'id', ignoreDuplicates: true),
      );

  @override
  Future<void> guardar(String tabla, List<FilaRemota> filas) =>
      _ejecutar(() => _cliente.from(tabla).upsert(filas, onConflict: 'id'));

  @override
  Future<void> borrar(String tabla, String id) =>
      _ejecutar(() => _cliente.from(tabla).delete().eq('id', id));

  @override
  Future<List<FilaRemota>> leerDesde(
    String tabla,
    String tiendaId, {
    required String? desde,
    required int limite,
    required int desplazamiento,
  }) => _ejecutar(() async {
    var consulta = _cliente.from(tabla).select().eq('tienda_id', tiendaId);
    if (desde != null) consulta = consulta.gte('sincronizado_en', desde);
    final filas = await consulta
        .order('sincronizado_en', ascending: true)
        .order('id', ascending: true)
        .range(desplazamiento, desplazamiento + limite - 1);
    return [for (final f in filas) Map<String, Object?>.from(f)];
  });

  /// Códigos de PostgreSQL que dicen "el servidor entendió y dijo que no": 22
  /// (dato mal formado), 23 (llave o regla de la tabla) y 42 (columna o tabla
  /// que no existe). PGRST204 y PGRST205 son lo mismo para PostgREST. Todo lo
  /// demás (sin red, sesión vencida, servicio caído) se reintenta.
  static final _rechazos = RegExp(r'^(22|23|42|PGRST20[45])');

  Future<T> _ejecutar<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on PostgrestException catch (e) {
      final codigo = e.code;
      if (codigo != null && _rechazos.hasMatch(codigo)) {
        throw RechazoDelServidor(e.message, codigo);
      }
      throw FalloDeRed(e.message);
    } catch (e) {
      throw FalloDeRed('$e');
    }
  }
}
