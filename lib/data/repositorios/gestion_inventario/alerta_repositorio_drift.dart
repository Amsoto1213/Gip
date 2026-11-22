import 'package:drift/drift.dart';
import 'package:gip/business/entidades/gestion_inventario/alerta_reabastecimiento.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_alerta_repositorio.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/data/local/base_local_drift.dart';

/// [IAlertaRepositorio] sobre la base local (drift), tabla
/// `alertas_reabastecimiento`. La fecha se guarda como el día local
/// "AAAA-MM-DD" (DI-25).
class AlertaRepositorioDrift implements IAlertaRepositorio {
  AlertaRepositorioDrift(this._base);

  final BaseLocalDrift _base;

  static const _tabla = 'alertas_reabastecimiento';

  /// Día local de [fecha] como "AAAA-MM-DD".
  static String diaComoTexto(DateTime fecha) {
    final f = fecha.toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${f.year}-${dos(f.month)}-${dos(f.day)}';
  }

  /// En una transacción (o la abierta): borra las alertas de la tienda y el
  /// día, inserta las nuevas y anota cada borrado (ELIMINAR) e inserción
  /// (INSERTAR) en `cola_pendientes` (DA-33). Así no se duplican (RD-11).
  @override
  Future<void> reemplazar(
    Tienda tienda,
    DateTime fecha,
    List<AlertaReabastecimiento> alertas,
  ) {
    final dia = diaComoTexto(fecha);
    final t = _base.alertasReabastecimiento;
    return _base.transaction(() async {
      final anteriores =
          await (_base.select(t)..where(
                (a) => a.tiendaId.equals(tienda.getId()) & a.fecha.equals(dia),
              ))
              .get();
      for (final anterior in anteriores) {
        await (_base.delete(t)..where((a) => a.id.equals(anterior.id))).go();
        await anotarEnCola(
          _base,
          tiendaId: tienda.getId(),
          tabla: _tabla,
          registroId: anterior.id,
          operacion: OperacionCola.eliminar,
        );
      }
      for (final alerta in alertas) {
        await _base
            .into(t)
            .insert(
              AlertasReabastecimientoCompanion.insert(
                id: alerta.getId(),
                tiendaId: tienda.getId(),
                itemId: alerta.getItemId(),
                fecha: dia,
                existencia: alerta.getExistencia(),
                consumoPromedioDiario: alerta.getConsumoPromedioDiario(),
                diasCobertura: alerta.getDiasCobertura(),
                provisional: alerta.isProvisional(),
              ),
            );
        await anotarEnCola(
          _base,
          tiendaId: tienda.getId(),
          tabla: _tabla,
          registroId: alerta.getId(),
          operacion: OperacionCola.insertar,
        );
      }
    });
  }

  /// Alertas del día con su ítem y producto, de menor a mayor cobertura.
  @override
  Future<List<AlertaReabastecimiento>> listarPorFecha(
    Tienda tienda,
    DateTime fecha,
  ) async {
    final a = _base.alertasReabastecimiento;
    final i = _base.itemsInventario;
    final p = _base.productos;
    final consulta =
        _base.select(a).join([
          innerJoin(i, i.id.equalsExp(a.itemId)),
          innerJoin(p, p.id.equalsExp(i.productoId)),
        ])..where(
          a.tiendaId.equals(tienda.getId()) &
              a.fecha.equals(diaComoTexto(fecha)),
        );
    final filas = await consulta.get();
    final alertas = [
      for (final f in filas)
        _aEntidad(f.readTable(a), f.readTable(i), f.readTable(p)),
    ];
    return alertas..sort((x, y) {
      final porDias = x.getDiasCobertura().compareTo(y.getDiasCobertura());
      if (porDias != 0) return porDias;
      return x.getNombreProducto().compareTo(y.getNombreProducto());
    });
  }

  AlertaReabastecimiento _aEntidad(
    FilaAlerta fila,
    FilaItemInventario item,
    FilaProducto producto,
  ) {
    final partes = fila.fecha.split('-').map(int.parse).toList();
    return AlertaReabastecimiento(
      fila.id,
      item.id,
      producto.id,
      producto.nombre,
      DateTime(partes[0], partes[1], partes[2]),
      fila.existencia,
      fila.consumoPromedioDiario,
      fila.diasCobertura,
      fila.provisional,
    );
  }
}
