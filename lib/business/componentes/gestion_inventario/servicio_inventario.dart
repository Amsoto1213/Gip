import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/ajuste_conteo.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
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
/// Tiene [crearItem] (CUS-18), la entrada de mercancía (CUS-01), la pérdida
/// o devolución (CUS-03) y el conteo físico (CUS-04).
class ServicioInventario {
  ServicioInventario(
    this._items,
    this._movimientos,
    this._umbralRevisionConteo,
    this._unidadTrabajo,
  );

  final IInventarioRepositorio _items;
  final IMovimientoInventarioRepositorio _movimientos;
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

  /// Productos con su stock: delega en items.listarItems; cada ítem trae su
  /// producto, ordenados por nombre (CUS-04, pasos 3 a 6).
  Future<List<ItemInventario>> listarExistencias(Tienda tienda) =>
      _items.listarItems(tienda);

  /// Obtiene el ítem con [obtenerItem] y devuelve cantidadContada − stock
  /// actual (IE-04). Positiva: sobra; negativa: falta; cero: cuadra.
  Future<Decimal> calcularDiferencia(
    Tienda tienda,
    Producto producto,
    Decimal cantidadContada,
  ) async {
    final item = await obtenerItem(tienda, producto);
    return cantidadContada - item.getStockActual();
  }

  /// Verdadero si |diferencia| **supera** el umbral de revisión: justo en el
  /// umbral no pide revisar (IE-04 b, DI-24). No bloquea.
  bool requiereRevision(Decimal diferencia) =>
      diferencia.abs() > _umbralRevisionConteo;

  /// Valida cantidadContada >= 0 (IE-04 b), calcula la diferencia, crea el
  /// [AjusteConteo] con la diferencia como cantidad y lo aplica con
  /// [aplicarMovimiento]: el stock queda igual a lo contado (RF-04). Una
  /// diferencia cero también se registra, como constancia del conteo (DI-24).
  Future<AjusteConteo> registrarConteo(
    Tienda tienda,
    Producto producto,
    Decimal cantidadContada,
  ) async {
    if (cantidadContada < Decimal.zero) {
      throw const ExcepcionCantidadContadaNegativa();
    }
    final item = await obtenerItem(tienda, producto);
    final ajuste = AjusteConteo(
      const Uuid().v4(),
      item,
      cantidadContada - item.getStockActual(),
      DateTime.now().toUtc(),
      cantidadContada,
    );
    await aplicarMovimiento(tienda, ajuste);
    return ajuste;
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

  /// Valida cantidad > 0 y motivo, obtiene el ítem, crea la [Merma] con id
  /// nuevo y cantidad negativa (DA-19) y la aplica con [aplicarMovimiento]
  /// (RF-03). [motivo] es nulo si el tendero no eligió ninguno: se rechaza con
  /// "Datos no válidos" (CUS-03, paso 5; DI-22). Si la cantidad supera la
  /// existencia se rechaza antes de abrir la transacción, con su propio
  /// mensaje (DI-22). El nuevo stock se lee en
  /// `merma.getItem().getStockActual()`.
  Future<Merma> registrarMerma(
    Tienda tienda,
    Producto producto,
    Decimal cantidad,
    MotivoMerma? motivo,
  ) async {
    if (cantidad <= Decimal.zero || motivo == null) {
      throw const ExcepcionDatosMermaNoValidos();
    }
    final item = await obtenerItem(tienda, producto);
    if (!hayExistencia(item, cantidad)) {
      throw const ExcepcionCantidadSuperaExistencia();
    }
    final merma = Merma(
      const Uuid().v4(),
      item,
      -cantidad,
      DateTime.now().toUtc(),
      motivo,
    );
    await aplicarMovimiento(tienda, merma);
    return merma;
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
