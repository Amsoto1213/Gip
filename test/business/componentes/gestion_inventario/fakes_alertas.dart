import 'package:gip/business/entidades/gestion_inventario/alerta_reabastecimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_alerta_repositorio.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_venta_perdida_repositorio.dart';

/// Alertas en memoria por tienda y día; reemplazar descarta las del día.
class AlertaRepositorioFalso implements IAlertaRepositorio {
  final Map<String, List<AlertaReabastecimiento>> datos = {};
  int reemplazos = 0;

  String _clave(Tienda t, DateTime f) =>
      '${t.getId()}_${f.year}-${f.month}-${f.day}';

  @override
  Future<void> reemplazar(
    Tienda tienda,
    DateTime fecha,
    List<AlertaReabastecimiento> alertas,
  ) async {
    reemplazos++;
    datos[_clave(tienda, fecha)] = List.of(alertas);
  }

  @override
  Future<List<AlertaReabastecimiento>> listarPorFecha(
    Tienda tienda,
    DateTime fecha,
  ) async => List.of(datos[_clave(tienda, fecha)] ?? const []);
}

/// Ventas perdidas en memoria por tienda; fechas en `[desde, hasta)`.
class VentaPerdidaRepositorioFalso implements IVentaPerdidaRepositorio {
  final Map<String, List<VentaPerdida>> datos = {};

  void agregar(Tienda tienda, VentaPerdida venta) =>
      datos.putIfAbsent(tienda.getId(), () => []).add(venta);

  @override
  Future<void> guardar(Tienda tienda, VentaPerdida ventaPerdida) async =>
      agregar(tienda, ventaPerdida);

  bool _enPeriodo(VentaPerdida v, DateTime desde, DateTime hasta) =>
      !v.getFecha().isBefore(desde) && v.getFecha().isBefore(hasta);

  @override
  Future<List<VentaPerdida>> buscarPorPeriodo(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async => (datos[tienda.getId()] ?? const [])
      .where((v) => _enPeriodo(v, desde, hasta))
      .toList();

  @override
  Future<List<VentaPerdida>> listarPorProducto(
    Producto producto,
    DateTime desde,
    DateTime hasta,
  ) async => datos.values
      .expand((l) => l)
      .where(
        (v) =>
            v.getProductoId() == producto.getId() &&
            _enPeriodo(v, desde, hasta),
      )
      .toList();
}
