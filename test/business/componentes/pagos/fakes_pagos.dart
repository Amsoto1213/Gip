import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/pagos/i_venta_repositorio.dart';

import '../gestion_inventario/fakes_catalogo.dart';

/// Ventas en memoria, por tienda y en orden de llegada.
class VentaRepositorioFalso implements IVentaRepositorio, Restaurable {
  final Map<String, List<Venta>> datos = {};
  Map<String, List<Venta>> _copia = {};

  final List<bool> guardadosEnTransaccion = [];
  UnidadTrabajoFalsa? unidad;

  List<Venta> de(Tienda t) => datos.putIfAbsent(t.getId(), () => []);

  @override
  void tomarCopia() =>
      _copia = {for (final e in datos.entries) e.key: List.of(e.value)};

  @override
  void restaurar() => datos
    ..clear()
    ..addAll(_copia);

  @override
  Future<void> guardar(Tienda tienda, Venta venta) async {
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    de(tienda).add(venta);
  }
}
