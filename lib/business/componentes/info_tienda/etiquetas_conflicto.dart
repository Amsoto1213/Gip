import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/ajuste_conteo.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';

/// Textos en el lenguaje del tendero con que `ServicioConciliacion` describe
/// los registros de un conflicto (RNF-25, DI-46). Dart puro: no sabe de
/// idiomas ni de `intl`; la hora se escribe como "10:42 a. m.".
abstract final class EtiquetasConflicto {
  /// "10:42 a. m." en la hora local.
  static String hora(DateTime momento) {
    final local = momento.toLocal();
    final h12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minutos = local.minute.toString().padLeft(2, '0');
    final sufijo = local.hour < 12 ? 'a. m.' : 'p. m.';
    return '$h12:$minutos $sufijo';
  }

  /// "19/11 10:42 a. m." en la hora local.
  static String diaYHora(DateTime momento) {
    final local = momento.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    return '$dia/$mes ${hora(momento)}';
  }

  /// "$ 8.000": pesos enteros con punto de miles; el signo va delante.
  static String pesos(Decimal valor) {
    final entero = valor.abs().round().toBigInt().toString();
    final grupos = StringBuffer();
    for (var i = 0; i < entero.length; i++) {
      if (i > 0 && (entero.length - i) % 3 == 0) grupos.write('.');
      grupos.write(entero[i]);
    }
    return '${valor < Decimal.zero ? '-' : ''}\$ $grupos';
  }

  /// Cantidad sin ceros de más: "24", "2.5".
  static String cantidad(Decimal valor) => valor.toString();

  /// "Entrada de 24 Huevo AA · factura FV-10231 · 19/11 10:42 a. m.".
  static String movimiento(MovimientoInventario m) {
    final producto = m.getItem().getProducto().getNombre();
    final cuando = diaYHora(m.getFecha());
    final cantidad = EtiquetasConflicto.cantidad(m.getCantidad().abs());
    if (m is EntradaMercancia) {
      return 'Entrada de $cantidad $producto${_factura(m.getNumeroFactura())}'
          ' · $cuando';
    }
    if (m is SalidaVenta) return 'Venta de $cantidad $producto · $cuando';
    if (m is Merma) return 'Pérdida de $cantidad $producto · $cuando';
    if (m is AjusteConteo) return 'Conteo de $producto · $cuando';
    return '$producto · $cuando';
  }

  static String _factura(String? numero) =>
      numero == null || numero.trim().isEmpty
      ? ''
      : ' · factura ${numero.trim()}';

  /// "Abono de $ 8.000 en efectivo · 19/11 10:42 a. m.".
  static String abono(Abono a) {
    final medio = a.getMedio() == MedioPago.nequi ? 'por Nequi' : 'en efectivo';
    return 'Abono de ${pesos(a.getMonto())} $medio · ${diaYHora(a.getFecha())}';
  }
}
