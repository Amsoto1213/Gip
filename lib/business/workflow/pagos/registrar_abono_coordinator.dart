import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/pagos/servicio_abonos.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';

/// Controller del caso de uso CUS-08 Registrar abono: registra el abono en
/// efectivo o por Nequi; delega en [ServicioAbonos]. La búsqueda del cliente y
/// de sus fiados la da ConsultarClienteCoordinator (CUS-19).
class RegistrarAbonoCoordinator {
  RegistrarAbonoCoordinator(this._servicioAbonos);

  final ServicioAbonos _servicioAbonos;

  /// Llama a servicioAbonos.registrarAbono y devuelve el [Abono].
  Future<Abono> registrarAbono(
    Tienda tienda,
    Fiado fiado,
    Decimal monto,
    MedioPago medio,
    String? referencia,
  ) => _servicioAbonos.registrarAbono(tienda, fiado, monto, medio, referencia);
}
