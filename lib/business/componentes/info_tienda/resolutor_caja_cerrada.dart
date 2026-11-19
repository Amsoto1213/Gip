import 'package:gip/business/componentes/info_tienda/resolutor_conflicto.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/interfaces/gestion_caja/i_caja_repositorio.dart';
import 'package:gip/transversal/errores/errores_conciliacion.dart';

/// Resuelve MOVIMIENTO_CAJA_CERRADA: el movimiento se acepta en su caja y se
/// recalcula la diferencia del cierre (DA-66).
class ResolutorCajaCerrada implements ResolutorConflicto {
  ResolutorCajaCerrada(this._cajas);

  final ICajaRepositorio _cajas;

  /// Verdadero si el tipo es MOVIMIENTO_CAJA_CERRADA.
  @override
  bool admite(ConflictoSincronizacion conflicto) =>
      conflicto.getTipo() == TipoConflicto.movimientoCajaCerrada;

  /// Busca la caja con `cajas.buscarPorId(tienda, primer id del conflicto)`,
  /// llama a `caja.recalcularDiferencia()` y guarda con
  /// `cajas.cerrar(tienda, caja)`. [idsElegidos] no se usa: el dinero
  /// registrado no se pierde. El efectivo contado y la fecha del cierre no
  /// cambian (DI-45).
  @override
  Future<void> resolver(
    Tienda tienda,
    ConflictoSincronizacion conflicto,
    List<String> idsElegidos,
  ) async {
    final caja = await _cajas.buscarPorId(
      tienda,
      conflicto.getIdsRegistros().first,
    );
    if (caja == null) {
      throw const ExcepcionRegistrosDelConflictoNoEncontrados();
    }
    caja.recalcularDiferencia();
    await _cajas.cerrar(tienda, caja);
  }
}
