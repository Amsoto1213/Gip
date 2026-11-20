import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/info_tienda/conciliar_coordinator.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/service_agents/sincronizacion/cambios_remotos_supabase.dart';
import 'package:gip/data/service_agents/sincronizacion/servidor_remoto_supabase.dart';
import 'package:gip/data/service_agents/sincronizacion/sincronizador.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lo que la app necesita para sincronizar (CUS-23, DI-47, DI-48).
typedef Sincronizacion = ({
  /// Sincroniza la tienda y devuelve lo que pasó.
  Sincronizador sincronizador,

  /// Avisa cada vez que este equipo escribe algo que hay que subir.
  Stream<void> escrituras,

  /// Avisa cada vez que otro equipo cambia algo de la tienda.
  Stream<void> Function(Tienda tienda) cambiosRemotos,
});

/// Arma el Sincronizador: sube la cola de pendientes y baja los cambios de los
/// demás equipos contra Supabase, y al terminar llama a
/// `ConciliarCoordinator.ejecutar`. El Composition Root le entrega el
/// coordinador para que la Data Layer no conozca el Workflow. Con él van las
/// dos señales para sincronizar al instante: las escrituras de este equipo y
/// los cambios de los demás (Supabase Realtime).
Sincronizacion registrarSincronizacion(
  BaseLocalDrift base,
  SupabaseClient cliente,
  ConciliarCoordinator conciliar,
) {
  final sincronizador = Sincronizador(
    base,
    ServidorRemotoSupabase(cliente),
    conciliar.ejecutar,
  );
  return (
    sincronizador: sincronizador,
    escrituras: sincronizador.escrituras,
    cambiosRemotos: CambiosRemotosSupabase(cliente).escuchar,
  );
}
