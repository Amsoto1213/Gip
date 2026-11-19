import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/info_tienda/resolutor_conflicto.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/interfaces/pagos/i_fiado_repositorio.dart';
import 'package:gip/transversal/errores/errores_conciliacion.dart';

/// Resuelve ABONO_EXCEDE_SALDO anulando los abonos que sobran y devolviendo el
/// dinero (DA-66).
class ResolutorAbonoExcedido implements ResolutorConflicto {
  ResolutorAbonoExcedido(this._fiados, this._servicioCaja);

  final IFiadoRepositorio _fiados;
  final ServicioCaja _servicioCaja;

  /// Descripción del egreso de caja con que se devuelve el efectivo.
  static const descripcionDevolucion = 'Devolución abono';

  /// Verdadero si el tipo es ABONO_EXCEDE_SALDO.
  @override
  bool admite(ConflictoSincronizacion conflicto) =>
      conflicto.getTipo() == TipoConflicto.abonoExcedeSaldo;

  /// El primer id del conflicto es el del fiado y los demás, sus abonos.
  /// Busca el fiado con `fiados.buscarPorId`; por cada abono de [idsElegidos]
  /// llama a `abono.anular()` y `fiados.anularAbono`, y si
  /// `abono.esEfectivo()` a `servicioCaja.registrarMovimiento(tienda, EGRESO,
  /// ANULACION, monto, 'Devolución abono')`; al final `fiado.recalcularSaldo()`
  /// y `fiados.actualizarSaldo`. Por Nequi la devolución se hace fuera del
  /// sistema.
  ///
  /// Antes de escribir nada comprueba que, sin los abonos elegidos, el saldo
  /// no quede negativo; si no, lanza [ExcepcionAbonoSigueExcedido]. Un abono
  /// que ya estaba anulado no se devuelve otra vez y los ids que no son del
  /// fiado se ignoran (DI-45).
  @override
  Future<void> resolver(
    Tienda tienda,
    ConflictoSincronizacion conflicto,
    List<String> idsElegidos,
  ) async {
    final fiado = await _fiados.buscarPorId(
      tienda,
      conflicto.getIdsRegistros().first,
    );
    if (fiado == null) {
      throw const ExcepcionRegistrosDelConflictoNoEncontrados();
    }

    final elegidos = idsElegidos.toSet();
    final aAnular = [
      for (final abono in fiado.getAbonos())
        if (!abono.isAnulado() && elegidos.contains(abono.getId())) abono,
    ];

    final sobrante = fiado
        .getAbonos()
        .where((a) => !a.isAnulado() && !aAnular.contains(a))
        .fold(fiado.getMontoInicial(), (saldo, a) => saldo - a.getMonto());
    if (sobrante < Decimal.zero) throw const ExcepcionAbonoSigueExcedido();

    for (final abono in aAnular) {
      abono.anular();
      await _fiados.anularAbono(tienda, fiado, abono);
      if (abono.esEfectivo()) {
        await _servicioCaja.registrarMovimiento(
          tienda,
          TipoMovimientoCaja.egreso,
          ClasificacionMovimiento.anulacion,
          abono.getMonto(),
          descripcionDevolucion,
        );
      }
    }
    fiado.recalcularSaldo();
    await _fiados.actualizarSaldo(tienda, fiado);
  }
}
