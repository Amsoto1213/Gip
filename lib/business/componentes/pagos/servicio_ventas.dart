import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/pagos/procesador_pago.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/pagos/anulacion_venta.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/i_unidad_trabajo.dart';
import 'package:gip/business/interfaces/pagos/i_venta_repositorio.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';
import 'package:uuid/uuid.dart';

/// Pure Fabrication y Creator de la venta: crea las líneas y los pagos, valida
/// las formas de pago al confirmar y confirma la venta (CUR-02, RF-02). No
/// guarda estado: recibe las líneas y las formas de pago en cada operación
/// (DA-54, DA-57).
///
/// Lista y anula ventas (CUS-20, DI-39).
class ServicioVentas {
  ServicioVentas(
    this._servicioInventario,
    this._procesadores,
    this._ventas,
    this._unidadTrabajo,
  );

  final ServicioInventario _servicioInventario;
  final List<ProcesadorPago> _procesadores;
  final IVentaRepositorio _ventas;
  final IUnidadTrabajo _unidadTrabajo;

  static const _maxFormasPago = 3;

  /// Si el producto ya está en [lineas], suma [cantidad] con [cambiarCantidad]
  /// y devuelve esa línea. Si no, obtiene el ítem, verifica la existencia
  /// (RN-01), crea la [LineaVenta] y la agrega a [lineas].
  Future<LineaVenta> agregarLinea(
    Tienda tienda,
    List<LineaVenta> lineas,
    Producto producto,
    Decimal cantidad,
  ) async {
    if (cantidad <= Decimal.zero) throw const ExcepcionCantidadNoValida();
    final existente = lineas
        .where((l) => l.getItem().getProducto().getId() == producto.getId())
        .firstOrNull;
    if (existente != null) {
      cambiarCantidad(existente, existente.getCantidad() + cantidad);
      return existente;
    }
    final item = await _servicioInventario.obtenerItem(tienda, producto);
    if (!_servicioInventario.hayExistencia(item, cantidad)) {
      throw const ExcepcionExistenciaInsuficiente();
    }
    final linea = LineaVenta(item, cantidad);
    lineas.add(linea);
    return linea;
  }

  /// Valida cantidad > 0 y la existencia (RN-01); si alcanza cambia la
  /// cantidad de la línea, si no rechaza y la línea queda igual.
  void cambiarCantidad(LineaVenta linea, Decimal cantidad) {
    if (cantidad <= Decimal.zero) throw const ExcepcionCantidadNoValida();
    if (!_servicioInventario.hayExistencia(linea.getItem(), cantidad)) {
      throw const ExcepcionExistenciaInsuficiente();
    }
    linea.setCantidad(cantidad);
  }

  /// Suma linea.calcularSubtotal() de cada línea.
  Decimal calcularTotal(List<LineaVenta> lineas) =>
      lineas.fold(Decimal.zero, (total, l) => total + l.calcularSubtotal());

  /// Creator: valida montoACubrir > 0 y montoRecibido >= montoACubrir, calcula
  /// cambio = montoRecibido - montoACubrir y crea el [PagoContado]. No lo
  /// guarda: la pantalla lo entrega en [confirmar].
  PagoContado crearPagoContado(Decimal montoACubrir, Decimal montoRecibido) {
    if (montoACubrir <= Decimal.zero) throw const ExcepcionMontoNoValido();
    if (montoRecibido < montoACubrir) throw const ExcepcionMontoInsuficiente();
    return PagoContado(
      const Uuid().v4(),
      montoRecibido,
      montoRecibido - montoACubrir,
    );
  }

  /// Creator: valida monto > 0 y crea el [PagoNequi]. Una referencia vacía
  /// queda nula. No lo guarda: la pantalla lo entrega en [confirmar].
  PagoNequi crearPagoNequi(Decimal monto, String? referencia) {
    if (monto <= Decimal.zero) throw const ExcepcionMontoNoValido();
    final ref = referencia?.trim();
    return PagoNequi(
      const Uuid().v4(),
      monto,
      (ref == null || ref.isEmpty) ? null : ref,
    );
  }

  /// De una a tres formas, sin repetir tipo, cada una cubre algo y entre todas
  /// suman el total (DA-20, DA-63, DA-72).
  void _validarFormasPago(List<FormaPago> formas, Decimal total) {
    final tipos = formas.map((f) => f.runtimeType).toSet();
    final suma = formas.fold(
      Decimal.zero,
      (s, f) => s + f.calcularMontoCubierto(),
    );
    final valido =
        formas.isNotEmpty &&
        formas.length <= _maxFormasPago &&
        tipos.length == formas.length &&
        formas.every((f) => f.calcularMontoCubierto() > Decimal.zero) &&
        suma == total;
    if (!valido) throw const ExcepcionFormasPagoNoValidas();
  }

  /// Valida las formas de pago con el total; luego, en una sola transacción,
  /// crea y guarda la [Venta], aplica una [SalidaVenta] negativa por línea y
  /// procesa cada forma de pago (RNF-04, DA-61). Si algo falla, o el stock
  /// quedaría negativo, no se guarda nada.
  ///
  /// El ítem de cada salida se vuelve a leer con obtenerItem, porque el de la
  /// línea trae el stock del momento en que se agregó (DI-21). El precio y el
  /// costo son los del producto de la línea, los mismos con que se calculó el
  /// total.
  Future<Venta> confirmar(
    Tienda tienda,
    List<LineaVenta> lineas,
    List<FormaPago> formas,
  ) async {
    final total = calcularTotal(lineas);
    _validarFormasPago(formas, total);

    late Venta venta;
    await _unidadTrabajo.ejecutar(() async {
      final fecha = DateTime.now().toUtc();
      venta = Venta(const Uuid().v4(), formas, total, fecha);
      await _ventas.guardar(tienda, venta);
      for (final linea in lineas) {
        final producto = linea.getItem().getProducto();
        final item = await _servicioInventario.obtenerItem(tienda, producto);
        final salida = SalidaVenta(
          const Uuid().v4(),
          item,
          -linea.getCantidad(),
          fecha,
          venta.getId(),
          producto.getPrecioVenta(),
          producto.getPrecioCompra(),
        );
        await _servicioInventario.aplicarMovimiento(tienda, salida);
      }
      for (final forma in formas) {
        await _procesadorPara(forma).procesar(tienda, venta, forma);
      }
    });
    return venta;
  }

  /// Polymorphism: el primer procesador que admite la forma de pago.
  ProcesadorPago _procesadorPara(FormaPago forma) =>
      _procesadores.where((p) => p.admite(forma)).firstOrNull ??
      (throw StateError('Sin procesador para ${forma.runtimeType}'));

  /// Ventas del periodo con sus formas de pago y su estado (anulada o no);
  /// delega en ventas.listarPorPeriodo (CUS-20, pasos 5 a 8).
  Future<List<Venta>> listarVentas(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) => _ventas.listarPorPeriodo(tienda, desde, hasta);

  /// Las salidas de cada venta, por el id de la venta, para mostrar sus
  /// productos; no está en EA (CUS-20, DI-39).
  Future<Map<String, List<SalidaVenta>>> listarSalidas(
    Tienda tienda,
    List<Venta> ventas,
  ) => _servicioInventario.listarSalidasDeVentas(tienda, ventas);

  /// Creator de [AnulacionVenta]. Rechaza si la venta ya está anulada o si el
  /// motivo está vacío; dentro de unidadTrabajo.ejecutar registra la
  /// anulación, devuelve las salidas al stock y revierte cada forma de pago
  /// (RNF-15, RNF-04). Si la caja de hoy está cerrada, el fiado ya tiene
  /// abonos o algo falla al guardar, no se guarda nada. La venta recibe su
  /// anulación al final, cuando todo se guardó (CUS-20).
  Future<AnulacionVenta> anular(
    Tienda tienda,
    Venta venta,
    String motivo,
    Usuario usuario,
  ) async {
    if (venta.isAnulada()) throw const ExcepcionVentaYaAnulada();
    final motivoLimpio = motivo.trim();
    if (motivoLimpio.isEmpty) {
      throw const ExcepcionMotivoAnulacionObligatorio();
    }
    final anulacion = AnulacionVenta(
      const Uuid().v4(),
      usuario,
      DateTime.now().toUtc(),
      motivoLimpio,
    );
    await _unidadTrabajo.ejecutar(() async {
      await _ventas.registrarAnulacion(tienda, venta, anulacion);
      await _servicioInventario.anularSalidas(tienda, venta);
      for (final forma in venta.getFormasPago()) {
        await _procesadorPara(forma).revertir(tienda, venta, forma);
      }
    });
    venta.anular(anulacion);
    return anulacion;
  }
}
