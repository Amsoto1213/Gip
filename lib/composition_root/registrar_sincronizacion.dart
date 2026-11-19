import 'package:gip/business/workflow/info_tienda/conciliar_coordinator.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/service_agents/sincronizacion/servidor_remoto_supabase.dart';
import 'package:gip/data/service_agents/sincronizacion/sincronizador.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Arma el Sincronizador (CUS-23, DI-47): sube la cola de pendientes y baja los
/// cambios de los demás equipos contra Supabase, y al terminar llama a
/// `ConciliarCoordinator.ejecutar`. El Composition Root le entrega el
/// coordinador para que la Data Layer no conozca el Workflow.
Sincronizador registrarSincronizacion(
  BaseLocalDrift base,
  SupabaseClient cliente,
  ConciliarCoordinator conciliar,
) => Sincronizador(base, ServidorRemotoSupabase(cliente), conciliar.ejecutar);
