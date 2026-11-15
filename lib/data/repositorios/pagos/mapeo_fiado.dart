import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/data/local/base_local_drift.dart';

/// Conversión entre las filas de `fiados` y la entidad [Fiado]. El estado se
/// guarda con el nombre del enum en mayúsculas (PENDIENTE, SALDADO, ANULADO).
abstract final class MapeoFiado {
  static String estadoATexto(EstadoFiado estado) => estado.name.toUpperCase();

  static EstadoFiado estadoDeTexto(String texto) =>
      EstadoFiado.values.byName(texto.toLowerCase());

  static Fiado aEntidad(FilaFiado fila, Cliente cliente) => Fiado.guardado(
    fila.id,
    fila.montoInicial,
    fila.fechaInicio,
    cliente,
    fila.saldoPendiente,
    estadoDeTexto(fila.estado),
  );
}
