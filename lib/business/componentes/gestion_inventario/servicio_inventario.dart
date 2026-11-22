import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/ajuste_conteo.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_inventario_repositorio.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_producto_repositorio.dart';
import 'package:gip/business/interfaces/i_unidad_trabajo.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';
import 'package:uuid/uuid.dart';

/// Pure Fabrication e Information Expert del stock: crea los movimientos y
/// mantiene el stock con stock nuevo = stock anterior + cantidad con signo
/// (ERS 3.2.1).
///
/// Tiene [crearItem] (CUS-18), la entrada de mercancía (CUS-01), la pérdida
/// o devolución (CUS-03), el conteo físico (CUS-04), la consulta de
/// existencias e historial (CUS-25), la anulación de las salidas de una venta
/// (CUS-20) y el recálculo del stock de la conciliación (CUS-22).
///
/// [_productos] no está en EA: la entrada actualiza el precio de compra del
/// producto con su costo (DI-33).
class ServicioInventario {
  ServicioInventario(
    this._items,
    this._movimientos,
    this._umbralRevisionConteo,
    this._unidadTrabajo,
    this._productos,
  );

  final IInventarioRepositorio _items;
  final IMovimientoInventarioRepositorio _movimientos;
  final Decimal _umbralRevisionConteo;
  final IUnidadTrabajo _unidadTrabajo;
  final IProductoRepositorio _productos;

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
  /// producto, ordenados por nombre (CUS-04, pasos 3 a 6; CUS-25, pasos 3 a 6).
  Future<List<ItemInventario>> listarExistencias(Tienda tienda) =>
      _items.listarItems(tienda);

  /// Historial del producto con fecha en `[desde, hasta)`: busca su ítem con
  /// items.buscarItem y devuelve movimientos.listarPorItem (entradas, salidas,
  /// mermas y ajustes, en cualquier estado, del más reciente al más antiguo).
  /// Un producto sin ítem no tiene historial: lista vacía, sin error, porque
  /// el diagrama no tiene ese caso (CUS-25, pasos 11 a 16; DI-32).
  Future<List<MovimientoInventario>> consultarMovimientos(
    Tienda tienda,
    Producto producto,
    DateTime desde,
    DateTime hasta,
  ) async {
    final item = await _items.buscarItem(tienda, producto);
    if (item == null) return const [];
    return _movimientos.listarPorItem(item, desde, hasta);
  }

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
  ///
  /// En la misma transacción, el costo de la entrada pasa a ser el precio de
  /// compra de [producto] (último costo), que las ventas siguientes guardan
  /// en su salida (DA-61). Un costo cero (bonificación del proveedor) o igual
  /// al que ya tiene no lo cambia. Si algo falla no se guarda nada y
  /// [producto] conserva su precio de compra (DI-33).
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
    final cambiaCosto =
        costoUnitario > Decimal.zero &&
        producto.getPrecioCompra() != costoUnitario;
    if (!cambiaCosto) {
      await aplicarMovimiento(tienda, entrada);
      return entrada;
    }
    final precioAnterior = producto.getPrecioCompra();
    final actualizadoAnterior = producto.getActualizadoEn();
    try {
      // aplicarMovimiento se une a esta transacción (DA-44) y, si falla,
      // devuelve el stock del ítem; el producto se devuelve aquí.
      await _unidadTrabajo.ejecutar(() async {
        producto
          ..setPrecioCompra(costoUnitario)
          ..setActualizadoEn(DateTime.now().toUtc());
        await _productos.guardar(tienda, producto);
        await aplicarMovimiento(tienda, entrada);
      });
    } catch (_) {
      producto
        ..setPrecioCompra(precioAnterior)
        ..setActualizadoEn(actualizadoAnterior);
      rethrow;
    }
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

  /// Dentro de unidadTrabajo.ejecutar: marca el movimiento ANULADO y devuelve su
  /// efecto al stock (stock nuevo = stock actual − cantidad); guarda con
  /// movimientos.actualizarEstado e items.guardarItem. Rechaza si el stock
  /// quedaría negativo. Si algo falla no se guarda nada y el movimiento y el
  /// ítem conservan su estado y su stock anteriores (CUS-20, RNF-15).
  Future<void> anularMovimiento(
    Tienda tienda,
    MovimientoInventario movimiento,
  ) async {
    final item = movimiento.getItem();
    final stockAnterior = item.getStockActual();
    final estadoAnterior = movimiento.getEstado();
    final nuevoStock = stockAnterior - movimiento.getCantidad();
    if (nuevoStock < Decimal.zero) throw const ExcepcionStockNegativo();
    try {
      await _unidadTrabajo.ejecutar(() async {
        movimiento.setEstado(EstadoMovimiento.anulado);
        item.setStockActual(nuevoStock);
        await _movimientos.actualizarEstado(tienda, movimiento);
        await _items.guardarItem(tienda, item);
      });
    } catch (_) {
      movimiento.setEstado(estadoAnterior);
      item.setStockActual(stockAnterior);
      rethrow;
    }
  }

  /// Suma los movimientos VIGENTES de todo el historial del ítem que devuelve
  /// movimientos.listarPorItem (los EN_REVISION y los ANULADOS no cuentan),
  /// asigna el resultado con item.setStockActual y lo guarda con
  /// items.guardarItem. Si el stock no cambió no escribe nada: cada escritura
  /// entra a la cola de sincronización y la conciliación recalcula en cada
  /// sincronización (DI-46). Devuelve el stock, que puede ser negativo: eso es
  /// justo lo que la conciliación muestra al propietario (ERS 3.2.1 c, DA-48,
  /// DI-45). Se une a la transacción abierta, si la hay.
  Future<Decimal> recalcularStock(Tienda tienda, ItemInventario item) async {
    final historial = await _movimientos.listarPorItem(
      item,
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      DateTime.utc(9999),
    );
    final stock = historial
        .where((m) => m.getEstado() == EstadoMovimiento.vigente)
        .fold(Decimal.zero, (suma, m) => suma + m.getCantidad());
    if (item.getStockActual() != stock) {
      item.setStockActual(stock);
      await _items.guardarItem(tienda, item);
    }
    return stock;
  }

  /// Busca las salidas de la venta [ventaId] con
  /// movimientos.listarSalidasPorVentas y llama a [anularMovimiento] por cada
  /// una que siga vigente: el stock vuelve (CUS-20). Recibe el id, no la
  /// `Venta` (DI-63).
  Future<void> anularSalidas(Tienda tienda, String ventaId) async {
    final salidas = await _movimientos.listarSalidasPorVentas(tienda, [
      ventaId,
    ]);
    for (final salida in salidas) {
      if (salida.getEstado() == EstadoMovimiento.vigente) {
        await anularMovimiento(tienda, salida);
      }
    }
  }

  /// Salidas de las ventas con esos ids ([idsVentas]), agrupadas por el id de
  /// cada venta, en cualquier estado: con ellas la pantalla muestra los
  /// productos de cada venta (CUS-20, DI-39, DI-63).
  Future<Map<String, List<SalidaVenta>>> listarSalidasDeVentas(
    Tienda tienda,
    List<String> idsVentas,
  ) async {
    if (idsVentas.isEmpty) return const {};
    final salidas = await _movimientos.listarSalidasPorVentas(
      tienda,
      idsVentas,
    );
    final porVenta = <String, List<SalidaVenta>>{};
    for (final s in salidas) {
      porVenta.putIfAbsent(s.getVentaId(), () => []).add(s);
    }
    return porVenta;
  }
}
