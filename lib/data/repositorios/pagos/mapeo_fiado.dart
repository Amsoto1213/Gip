import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/data/local/base_local_drift.dart';

/// Conversión entre las filas de `fiados` y la entidad [Fiado]. El estado se
/// guarda con el nombre del enum en mayúsculas (PENDIENTE, SALDADO, ANULADO).
abstract final class MapeoFiado {
  static String estadoATexto(EstadoFiado estado) => estado.name.toUpperCase();

  static EstadoFiado estadoDeTexto(String texto) =>
      EstadoFiado.values.byName(texto.toLowerCase());

  static String medioATexto(MedioPago medio) => medio.name.toUpperCase();

  static MedioPago medioDeTexto(String texto) =>
      MedioPago.values.byName(texto.toLowerCase());

  static Abono abonoAEntidad(FilaAbono fila) => Abono(
    fila.id,
    fila.monto,
    fila.fecha,
    medioDeTexto(fila.medio),
    fila.referencia,
    anulado: fila.anulado,
  );

  /// [abonos] son los abonos de este fiado (los anulados no cuentan para el
  /// saldo, que ya viene guardado).
  static Fiado aEntidad(
    FilaFiado fila,
    Cliente cliente, [
    List<FilaAbono> abonos = const [],
  ]) => Fiado.guardado(
    fila.id,
    fila.montoInicial,
    fila.fechaInicio,
    cliente,
    fila.saldoPendiente,
    estadoDeTexto(fila.estado),
    abonos.map(abonoAEntidad).toList(),
  );
}
