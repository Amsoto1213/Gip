import 'package:gip/business/componentes/pagos/procesador_pago.dart';
import 'package:gip/business/componentes/pagos/servicio_fiados.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

/// Pago fiado: deja el saldo pendiente a nombre del cliente (RF-07, CUR-07).
/// No mueve la caja.
class ProcesadorFiado implements ProcesadorPago {
  ProcesadorFiado(this._servicioFiados);

  final ServicioFiados _servicioFiados;

  @override
  bool admite(FormaPago forma) => forma is Fiado;

  /// Llama a servicioFiados.registrarFiado(tienda, forma as Fiado).
  @override
  Future<void> procesar(Tienda tienda, Venta venta, FormaPago forma) =>
      _servicioFiados.registrarFiado(tienda, forma as Fiado);

  /// Llama a servicioFiados.anularFiado(tienda, forma as Fiado): rechaza si el
  /// fiado ya tiene abonos (CUS-20).
  @override
  Future<void> revertir(Tienda tienda, Venta venta, FormaPago forma) =>
      _servicioFiados.anularFiado(tienda, forma as Fiado);
}
