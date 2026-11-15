import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';

/// Pure Fabrication: consolida las salidas de inventario en reportes. No
/// calcula montos por su cuenta: se los pide a quien tiene los datos
/// (`SalidaVenta.calcularMargen`), con el precio y el costo guardados en cada
/// salida (DA-61, DA-72).
///
/// Por ahora solo recibe lo que necesita CUS-09 (el historial de movimientos);
/// el resto de las dependencias de EA llegan con CUS-10, CUS-11 y CUS-12
/// (DI-28).
class ServicioReportes {
  ServicioReportes(this._movimientos);

  final IMovimientoInventarioRepositorio _movimientos;

  /// Margen de ganancia por producto en `[desde, hasta)`: suma de
  /// `salida.calcularMargen()` de las salidas vigentes de cada producto (RF-08).
  /// Si alguna salida del producto devuelve null, el valor del producto es
  /// null: dato incompleto (ERS 3.2.4, DA-61, DA-72). Los productos sin
  /// salidas en el periodo no aparecen. Los productos se agrupan por id.
  Future<Map<Producto, Decimal?>> calcularMargenes(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async {
    final salidas = await _movimientos.listarSalidasPorTienda(
      tienda,
      desde,
      hasta,
    );
    final productos = <String, Producto>{};
    final margenes = <String, Decimal>{};
    final incompletos = <String>{};
    for (final salida in salidas) {
      final producto = salida.getItem().getProducto();
      final id = producto.getId();
      productos.putIfAbsent(id, () => producto);
      final margen = salida.calcularMargen();
      if (margen == null) {
        incompletos.add(id);
      } else {
        margenes.update(id, (suma) => suma + margen, ifAbsent: () => margen);
      }
    }
    return {
      for (final e in productos.entries)
        e.value: incompletos.contains(e.key) ? null : margenes[e.key],
    };
  }
}
