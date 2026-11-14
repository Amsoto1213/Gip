import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_inventario_repositorio.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';
import 'package:gip/business/interfaces/i_unidad_trabajo.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';
import 'package:uuid/uuid.dart';

/// Pure Fabrication e Information Expert del stock: crea los movimientos y
/// mantiene el stock con stock nuevo = stock anterior + cantidad con signo
/// (ERS 3.2.1).
///
/// Tiene [crearItem] (CUS-18) y la entrada de mercancía (CUS-01).
/// `umbralRevisionConteo` está en el constructor de EA y lo usará CUS-04
/// (DI-15).
class ServicioInventario {
  ServicioInventario(
    this._items,
    this._movimientos,
    this._umbralRevisionConteo,
    this._unidadTrabajo,
  );

  final IInventarioRepositorio _items;
  final IMovimientoInventarioRepositorio _movimientos;
  // Pendiente (DI-15): CUS-04.
  // ignore: unused_field
  final Decimal _umbralRevisionConteo;
  final IUnidadTrabajo _unidadTrabajo;

  /// Creator: crea el [ItemInventario] con id nuevo y stock cero y lo guarda
  /// con items.guardarItem. Lo llama `ServicioCatalogo.crearProducto` dentro de
  /// su transacción.
  Future<ItemInventario> crearItem(Tienda tienda, Producto producto) async {
    final item = ItemInventario(const Uuid().v4(), producto, Decimal.zero);
    await _items.guardarItem(tienda, item);
    return item;
  }

  /// Llama a items.buscarItem; rechaza si el producto no tiene ítem (lo crea
  /// `ServicioCatalogo` al crear el producto).
  Future<ItemInventario> obtenerItem(Tienda tienda, Producto producto) async {
    final item = await _items.buscarItem(tienda, producto);
    if (item == null) throw const ExcepcionProductoSinInventario();
    return item;
  }

  /// Verdadero si el stock del ítem alcanza para [cantidad] (RN-01).
  bool hayExistencia(ItemInventario item, Decimal cantidad) =>
      item.getStockActual() >= cantidad;

  /// Compara [costoUnitario] con el de la última entrada VIGENTE del ítem.
  /// Sin entradas anteriores no hay advertencia. No bloquea (IE-02).
  Future<bool> costoDifiereDelHistorico(
    Tienda tienda,
    Producto producto,
    Decimal costoUnitario,
  ) async {
    final item = await obtenerItem(tienda, producto);
    final ultimaEntrada = await _movimientos.buscarUltimaEntrada(item);
    return ultimaEntrada != null &&
        ultimaEntrada.getCostoUnitario() != costoUnitario;
  }

  /// Valida cantidad > 0 y costo >= 0, crea la [EntradaMercancia] con id nuevo
  /// y la aplica con [aplicarMovimiento] (RF-01). Un número de factura vacío se
  /// guarda como nulo (IE-02). El nuevo stock se lee en
  /// `entrada.getItem().getStockActual()`.
  Future<EntradaMercancia> registrarEntrada(
    Tienda tienda,
    Producto producto,
    Decimal cantidad,
    Decimal costoUnitario,
    String? numeroFactura,
  ) async {
    if (cantidad <= Decimal.zero || costoUnitario < Decimal.zero) {
      throw const ExcepcionDatosEntradaNoValidos();
    }
    final item = await obtenerItem(tienda, producto);
    final factura = numeroFactura?.trim();
    final entrada = EntradaMercancia(
      const Uuid().v4(),
      item,
      cantidad,
      DateTime.now().toUtc(),
      costoUnitario,
      (factura == null || factura.isEmpty) ? null : factura,
    );
    await aplicarMovimiento(tienda, entrada);
    return entrada;
  }

  /// Dentro de unidadTrabajo.ejecutar: guarda el movimiento y el nuevo stock
  /// (stock anterior + cantidad con signo); bloquea si el stock queda negativo
  /// (ERS 3.2.1 a, RNF-04). Si algo falla no se guarda nada y el ítem conserva
  /// su stock anterior.
  Future<void> aplicarMovimiento(
    Tienda tienda,
    MovimientoInventario movimiento,
  ) async {
    final item = movimiento.getItem();
    final stockAnterior = item.getStockActual();
    final nuevoStock = stockAnterior + movimiento.getCantidad();
    if (nuevoStock < Decimal.zero) throw const ExcepcionStockNegativo();
    try {
      await _unidadTrabajo.ejecutar(() async {
        item.setStockActual(nuevoStock);
        await _movimientos.guardar(tienda, movimiento);
        await _items.guardarItem(tienda, item);
      });
    } catch (_) {
      item.setStockActual(stockAnterior);
      rethrow;
    }
  }
}
