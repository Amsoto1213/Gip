import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/info_tienda/i_estado_sincronizacion.dart';
import 'package:gip/data/local/base_local_drift.dart';

/// [IEstadoSincronizacion] sobre la base local: hay pendientes mientras
/// `cola_pendientes` tenga alguna fila de la tienda (ERS 3.2.5 c, DI-29). El
/// Sincronizador (CUS-23, DI-47) la vacía cada vez que sube; el reporte lo
/// muestra como información, no como error.
class EstadoSincronizacionDrift implements IEstadoSincronizacion {
  EstadoSincronizacionDrift(this._base);

  final BaseLocalDrift _base;

  @override
  Future<bool> hayPendientes(Tienda tienda) async {
    final cola = _base.colaPendientes;
    final fila =
        await (_base.select(cola)
              ..where((c) => c.tiendaId.equals(tienda.getId()))
              ..limit(1))
            .getSingleOrNull();
    return fila != null;
  }
}
