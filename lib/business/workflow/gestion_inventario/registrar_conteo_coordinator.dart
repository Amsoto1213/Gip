import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/ajuste_conteo.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Controller del caso de uso CUS-04 Registrar conteo físico: recibe las
/// operaciones del sistema desde la presentación y delega en
/// [ServicioInventario]; no contiene reglas de negocio.
class RegistrarConteoCoordinator {
  RegistrarConteoCoordinator(this._servicioInventario);

  final ServicioInventario _servicioInventario;

  /// Llama a servicioInventario.listarExistencias: la pantalla muestra cada
  /// producto con un campo para la cantidad contada (IE-04 e).
  Future<List<ItemInventario>> listarExistencias(Tienda tienda) =>
      _servicioInventario.listarExistencias(tienda);

  /// Llama a servicioInventario.calcularDiferencia (IE-04).
  Future<Decimal> calcularDiferencia(
    Tienda tienda,
    Producto producto,
    Decimal cantidadContada,
  ) =>
      _servicioInventario.calcularDiferencia(tienda, producto, cantidadContada);

  /// Devuelve servicioInventario.requiereRevision.
  bool requiereRevision(Decimal diferencia) =>
      _servicioInventario.requiereRevision(diferencia);

  /// Llama a servicioInventario.registrarConteo; el nuevo stock se lee en
  /// `ajuste.getItem().getStockActual()`.
  Future<AjusteConteo> confirmarAjuste(
    Tienda tienda,
    Producto producto,
    Decimal cantidadContada,
  ) => _servicioInventario.registrarConteo(tienda, producto, cantidadContada);
}
