import 'package:gip/data/local/base_local_drift.dart';
import 'package:uuid/uuid.dart';

/// Operaciones que se anotan en `cola_pendientes`.
abstract final class OperacionCola {
  static const insertar = 'INSERTAR';
  static const actualizar = 'ACTUALIZAR';

  /// Borrado de una fila; hoy solo lo usa el reemplazo de las alertas del día
  /// (DI-25). Los registros de solo agregar nunca se borran (RNF-15).
  static const eliminar = 'ELIMINAR';
}

/// Anota una escritura local en `cola_pendientes` para subirla a Supabase.
/// Hay que llamarla dentro de la misma transacción que la escritura (DA-33).
Future<void> anotarEnCola(
  BaseLocalDrift base, {
  required String tiendaId,
  required String tabla,
  required String registroId,
  required String operacion,
}) => base
    .into(base.colaPendientes)
    .insert(
      ColaPendientesCompanion.insert(
        id: const Uuid().v4(),
        tiendaId: tiendaId,
        tabla: tabla,
        registroId: registroId,
        operacion: operacion,
        creadoEn: DateTime.now().toUtc(),
      ),
    );
