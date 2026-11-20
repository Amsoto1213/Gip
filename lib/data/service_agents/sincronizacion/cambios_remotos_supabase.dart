import 'dart:async';

import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/data/service_agents/sincronizacion/tablas_sincronizables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Avisa en el momento en que otro equipo cambia algo de la tienda (DI-48):
/// escucha Supabase Realtime en las tablas que se sincronizan y emite un evento
/// por cada cambio. No trae los datos del cambio: es solo la señal para
/// sincronizar, que sí trae todo con sus reglas de choque. Emite también cada
/// vez que se (re)conecta, para recoger lo que pasó mientras no había conexión.
///
/// Necesita que las tablas estén en la publicación `supabase_realtime`
/// (migración `20261121100000_sincronizacion_tiempo_real.sql`). Sin RLS ni
/// políticas (DI-05), por eso el filtro por `tienda_id` va en la suscripción.
class CambiosRemotosSupabase {
  CambiosRemotosSupabase(this._cliente);

  final SupabaseClient _cliente;

  /// Eventos de la tienda mientras alguien escuche el flujo; al cancelar, se
  /// cierra el canal.
  Stream<void> escuchar(Tienda tienda) {
    RealtimeChannel? canal;
    late final StreamController<void> controlador;
    controlador = StreamController<void>(
      onListen: () {
        final nuevo = _cliente.channel('sincronizacion-${tienda.getId()}');
        for (final tabla in [
          for (final t in tablasSincronizables) t.nombre,
          tablaEliminados,
        ]) {
          nuevo.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: tabla,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'tienda_id',
              value: tienda.getId(),
            ),
            callback: (_) => controlador.add(null),
          );
        }
        nuevo.subscribe((estado, _) {
          if (estado == RealtimeSubscribeStatus.subscribed) {
            controlador.add(null);
          }
        });
        canal = nuevo;
      },
      onCancel: () async {
        final abierto = canal;
        canal = null;
        if (abierto != null) await _cliente.removeChannel(abierto);
      },
    );
    return controlador.stream;
  }
}
