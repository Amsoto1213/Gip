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

  /// Pendiente: llega con la tabla `abonos` (CUS-08).
  @override
  Future<void> registrarAbono(Tienda tienda, Fiado fiado, Abono abono) =>
      throw UnimplementedError('La tabla abonos llega en el siguiente paso');
}
