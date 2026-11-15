import 'package:drift/drift.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/interfaces/pagos/i_fiado_repositorio.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/pagos/mapeo_fiado.dart';

/// [IFiadoRepositorio] sobre la base local (drift).
class FiadoRepositorioDrift implements IFiadoRepositorio {
  FiadoRepositorioDrift(this._base);

  final BaseLocalDrift _base;

  static const _tabla = 'fiados';

  /// Inserta el fiado (su fila FIADO de `formas_pago` ya la guardó la venta,
  /// con el mismo id) y lo anota en `cola_pendientes`. Se une a la transacción
  /// de la venta: si algo falla, no queda nada (RNF-04, DA-33).
  @override
  Future<void> crear(Tienda tienda, Fiado fiado) => _base.transaction(() async {
    await _base
        .into(_base.fiados)
        .insert(
          FiadosCompanion.insert(
            id: fiado.getId(),
            tiendaId: tienda.getId(),
            clienteId: fiado.getCliente().getId(),
            montoInicial: fiado.getMontoInicial(),
            saldoPendiente: fiado.getSaldoPendiente(),
            estado: MapeoFiado.estadoATexto(fiado.getEstado()),
            fechaInicio: fiado.getFechaInicio(),
          ),
        );
    await anotarEnCola(
      _base,
      tiendaId: tienda.getId(),
      tabla: _tabla,
      registroId: fiado.getId(),
      operacion: OperacionCola.insertar,
    );
  });

  /// En una transacción inserta solo el abono nuevo, actualiza solo el saldo y
  /// el estado del fiado (que [Fiado.registrarAbono] ya recalculó) y anota las
  /// dos escrituras en `cola_pendientes` (RNF-04, DA-33, DA-46). Se une a la
  /// transacción de ServicioAbonos: si la caja falla, no queda nada.
  @override
  Future<void> registrarAbono(Tienda tienda, Fiado fiado, Abono abono) =>
      _base.transaction(() async {
        await _base
            .into(_base.abonos)
            .insert(
              AbonosCompanion.insert(
                id: abono.getId(),
                tiendaId: tienda.getId(),
                fiadoId: fiado.getId(),
                monto: abono.getMonto(),
                fecha: abono.getFecha(),
                medio: MapeoFiado.medioATexto(abono.getMedio()),
                referencia: Value(abono.getReferencia()),
                anulado: Value(abono.isAnulado()),
              ),
            );
        await anotarEnCola(
          _base,
          tiendaId: tienda.getId(),
          tabla: 'abonos',
          registroId: abono.getId(),
          operacion: OperacionCola.insertar,
        );
        await (_base.update(_base.fiados)..where(
              (f) =>
                  f.id.equals(fiado.getId()) &
                  f.tiendaId.equals(tienda.getId()),
            ))
            .write(
              FiadosCompanion(
                saldoPendiente: Value(fiado.getSaldoPendiente()),
                estado: Value(MapeoFiado.estadoATexto(fiado.getEstado())),
              ),
            );
        await anotarEnCola(
          _base,
          tiendaId: tienda.getId(),
          tabla: _tabla,
          registroId: fiado.getId(),
          operacion: OperacionCola.actualizar,
        );
      });
}
