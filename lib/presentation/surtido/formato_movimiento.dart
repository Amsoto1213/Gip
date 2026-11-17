import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/ajuste_conteo.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/surtido/widgets_movimiento.dart';

/// Textos con que la lista de existencias muestra un movimiento (CUS-25).

const _meses = [
  'ene.',
  'feb.',
  'mar.',
  'abr.',
  'may.',
  'jun.',
  'jul.',
  'ago.',
  'sep.',
  'oct.',
  'nov.',
  'dic.',
];

/// Tipo del movimiento en una palabra: "Entrada", "Venta", "Pérdida" o
/// "Conteo".
String tipoMovimiento(MovimientoInventario movimiento) => switch (movimiento) {
  EntradaMercancia() => 'Entrada',
  SalidaVenta() => 'Venta',
  Merma() => 'Pérdida',
  AjusteConteo() => 'Conteo',
  _ => 'Movimiento',
};

/// Tipo con su detalle: "Entrada FV-10231", "Pérdida (vencido)".
String descripcionMovimiento(MovimientoInventario movimiento) {
  if (movimiento is EntradaMercancia) {
    final factura = movimiento.getNumeroFactura();
    if (factura != null) return 'Entrada $factura';
  }
  if (movimiento is Merma) {
    return 'Pérdida (${nombreMotivo(movimiento.getMotivo()).toLowerCase()})';
  }
  return tipoMovimiento(movimiento);
}

/// Cantidad con su signo: "+24", "−1", "0". Lo que resta usa el signo menos
/// tipográfico, como en Pérdida.
String cantidadConSigno(Decimal cantidad) {
  if (cantidad > Decimal.zero) return '+${mostrarCantidad(cantidad)}';
  if (cantidad < Decimal.zero) return '−${mostrarCantidad(cantidad.abs())}';
  return '0';
}

/// "4:10 p. m." en hora local.
String _hora(DateTime local) {
  final hora12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minutos = local.minute.toString().padLeft(2, '0');
  final sufijo = local.hour < 12 ? 'a. m.' : 'p. m.';
  return '$hora12:$minutos $sufijo';
}

/// Día de [fecha] (UTC) respecto a [ahora], en hora local: "Hoy", "Ayer",
/// "9 nov." o, de otro año, "9 nov. 2025".
String _dia(DateTime fecha, DateTime ahora) {
  final f = fecha.toLocal();
  final dia = DateTime(f.year, f.month, f.day);
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  if (dia == hoy) return 'Hoy';
  if (dia == DateTime(hoy.year, hoy.month, hoy.day - 1)) return 'Ayer';
  final mes = '${f.day} ${_meses[f.month - 1]}';
  return f.year == ahora.year ? mes : '$mes ${f.year}';
}

/// Cuándo fue, con la hora: "Hoy 4:10 p. m.", "Ayer 7:40 p. m.",
/// "9 nov. 7:40 p. m." (panel de últimos movimientos).
String cuandoMovimiento(DateTime fecha, DateTime ahora) =>
    '${_dia(fecha, ahora)} ${_hora(fecha.toLocal())}';

/// Columna "Último movimiento" de la web: "Venta · hoy 3:52 p. m.",
/// "Conteo · 9 nov." (sin hora si no es de hoy ni de ayer, como el mockup).
String resumenUltimoMovimiento(
  MovimientoInventario movimiento,
  DateTime ahora,
) {
  final dia = _dia(movimiento.getFecha(), ahora);
  final cuando = switch (dia) {
    'Hoy' ||
    'Ayer' => '${dia.toLowerCase()} ${_hora(movimiento.getFecha().toLocal())}',
    _ => dia,
  };
  return '${tipoMovimiento(movimiento)} · $cuando';
}

/// Píldora del estado cuando el movimiento no cuenta para la existencia:
/// "En revisión" (conciliación) o "Anulado". Null si está VIGENTE (DA-50).
({String texto, TonoEstado tono})? estadoMovimiento(
  MovimientoInventario movimiento,
) => switch (movimiento.getEstado()) {
  EstadoMovimiento.vigente => null,
  EstadoMovimiento.enRevision => (
    texto: 'En revisión',
    tono: TonoEstado.informativo,
  ),
  EstadoMovimiento.anulado => (texto: 'Anulado', tono: TonoEstado.error),
};
