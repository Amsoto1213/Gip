import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/business/interfaces/i_unidad_trabajo.dart';
import 'package:gip/business/interfaces/pagos/i_fiado_repositorio.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';
import 'package:uuid/uuid.dart';

/// Pure Fabrication de los abonos (CUR-08, RNF-04): registra el pago de un
/// fiado en efectivo o por Nequi y, si es en efectivo, el ingreso en la caja,
/// todo en una transacción. Es el único que depende de la caja (DA-69).
class ServicioAbonos {
  ServicioAbonos(this._fiados, this._servicioCaja, this._unidadTrabajo);

  final IFiadoRepositorio _fiados;
  final ServicioCaja _servicioCaja;
  final IUnidadTrabajo _unidadTrabajo;

  /// Valida monto > 0 y no mayor al saldo (IE-06) y crea el [Abono] con su
  /// medio; dentro de la unidad de trabajo llama a fiado.registrarAbono (baja
  /// el saldo) y a fiados.registrarAbono; si el abono es en efectivo, también
  /// a servicioCaja.registrarIngreso(tienda, monto, 'Abono'). Por Nequi no
  /// mueve la caja (DA-64).
  ///
  /// La referencia solo se guarda con Nequi y vacía queda nula (DI-27).
  ///
  /// Si el guardado falla, la base se deshace pero [fiado] ya quedó cambiado
  /// en memoria: quien llama debe volver a leerlo de la base (DI-27).
  Future<Abono> registrarAbono(
    Tienda tienda,
    Fiado fiado,
    Decimal monto,
    MedioPago medio,
    String? referencia,
  ) async {
    if (monto <= Decimal.zero || monto > fiado.getSaldoPendiente()) {
      throw const ExcepcionMontoAbonoNoValido();
    }
    final limpia = referencia?.trim();
    final abono = Abono(
      const Uuid().v4(),
      monto,
      DateTime.now().toUtc(),
      medio,
      medio == MedioPago.nequi && limpia != null && limpia.isNotEmpty
          ? limpia
          : null,
    );
    await _unidadTrabajo.ejecutar(() async {
      fiado.registrarAbono(abono);
      await _fiados.registrarAbono(tienda, fiado, abono);
      if (abono.esEfectivo()) {
        await _servicioCaja.registrarIngreso(tienda, monto, 'Abono');
      }
    });
    return abono;
  }
}
