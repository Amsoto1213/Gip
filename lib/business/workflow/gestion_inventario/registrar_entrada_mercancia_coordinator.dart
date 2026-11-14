import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Controller del caso de uso CUS-01 Registrar entrada de mercancía: recibe
/// las operaciones del sistema desde la presentación y delega en
/// [ServicioInventario]; no contiene reglas de negocio.
class RegistrarEntradaMercanciaCoordinator {
  RegistrarEntradaMercanciaCoordinator(this._servicioInventario);

  final ServicioInventario _servicioInventario;

  /// Llama a servicioInventario.costoDifiereDelHistorico. Verdadero si el
  /// costo es distinto al de la última entrada (advertencia que no bloquea).
  Future<bool> verificarCosto(
    Tienda tienda,
    Producto producto,
    Decimal costoUnitario,
  ) => _servicioInventario.costoDifiereDelHistorico(
    tienda,
    producto,
    costoUnitario,
  );

  /// Llama a servicioInventario.registrarEntrada y devuelve la entrada; el
  /// nuevo stock se lee en `entrada.getItem().getStockActual()`.
  Future<EntradaMercancia> registrarEntrada(
    Tienda tienda,
    Producto producto,
    Decimal cantidad,
    Decimal costoUnitario,
    String? numeroFactura,
  ) => _servicioInventario.registrarEntrada(
    tienda,
    producto,
    cantidad,
    costoUnitario,
    numeroFactura,
  );
}
