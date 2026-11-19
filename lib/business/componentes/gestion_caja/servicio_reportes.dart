import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/reporte_diario.dart';
import 'package:gip/business/entidades/gestion_caja/rotacion.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/interfaces/gestion_caja/i_caja_repositorio.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_inventario_repositorio.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';
import 'package:gip/business/interfaces/info_tienda/i_estado_sincronizacion.dart';
import 'package:gip/business/interfaces/pagos/i_fiado_repositorio.dart';
import 'package:gip/business/interfaces/pagos/i_venta_repositorio.dart';

/// Pure Fabrication: consolida las salidas de inventario en reportes. No
/// calcula montos por su cuenta: se los pide a quien tiene los datos
/// (`SalidaVenta.calcularMargen`), con el precio y el costo guardados en cada
/// salida (DA-61, DA-72).
///
/// Recibe lo que necesitan CUS-09, CUS-10 y CUS-12 (DI-28, DI-29, DI-40).
class ServicioReportes {
  ServicioReportes(
    this._ventas,
    this._movimientos,
    this._cajas,
    this._fiados,
    this._estadoSincronizacion,
    this._items,
  );

  final IVentaRepositorio _ventas;
  final IMovimientoInventarioRepositorio _movimientos;
  final ICajaRepositorio _cajas;
  final IFiadoRepositorio _fiados;
  final IEstadoSincronizacion _estadoSincronizacion;
  final IInventarioRepositorio _items;

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

  /// Reporte del día [fecha] (día local; la hora no cuenta), sin guardarlo
  /// (RF-09, RF-10, DA-40). Cada total lo calcula la entidad que tiene el dato
  /// (DA-72): `venta.getTotal()`, `forma.calcularMontoCubierto()` de Fiado y
  /// PagoNequi, `salida.calcularMargen()`, `entrada.calcularCostoTotal()`,
  /// `abono.getMonto()` y `movimiento.esDelNegocio()`. Sin abonos anulados; las
  /// ventas y salidas anuladas ya no vienen de los repositorios (DI-29).
  ///
  /// Incompleto si alguna salida no tiene costo: esa salida no suma al margen.
  /// Utilidad = margen − gastos del negocio; no resta retiros personales ni
  /// devoluciones por anulación. Parcial si quedan operaciones sin subir.
  Future<ReporteDiario> generarReporteDiario(
    Tienda tienda,
    DateTime fecha,
  ) async {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final desde = dia;
    final hasta = DateTime(dia.year, dia.month, dia.day + 1);

    final ventas = await _ventas.listarPorPeriodo(tienda, desde, hasta);
    var totalVentas = Decimal.zero;
    var ventasFiadas = Decimal.zero;
    var ventasNequi = Decimal.zero;
    for (final venta in ventas) {
      // Las ventas anuladas no cuentan (CUS-20, DI-39).
      if (venta.isAnulada()) continue;
      totalVentas += venta.getTotal();
      for (final forma in venta.getFormasPago()) {
        if (forma is Fiado) ventasFiadas += forma.calcularMontoCubierto();
        if (forma is PagoNequi) ventasNequi += forma.calcularMontoCubierto();
      }
    }

    final salidas = await _movimientos.listarSalidasPorTienda(
      tienda,
      desde,
      hasta,
    );
    var margen = Decimal.zero;
    var incompleto = false;
    for (final salida in salidas) {
      final m = salida.calcularMargen();
      if (m == null) {
        incompleto = true;
      } else {
        margen += m;
      }
    }

    final entradas = await _movimientos.listarEntradasPorTienda(
      tienda,
      desde,
      hasta,
    );
    final totalEntradas = entradas.fold(
      Decimal.zero,
      (suma, e) => suma + e.calcularCostoTotal(),
    );

    final abonos = (await _fiados.listarAbonos(
      tienda,
      desde,
      hasta,
    )).where((a) => !a.isAnulado());
    var abonosRecibidos = Decimal.zero;
    var abonosNequi = Decimal.zero;
    for (final abono in abonos) {
      abonosRecibidos += abono.getMonto();
      if (abono.getMedio() == MedioPago.nequi) abonosNequi += abono.getMonto();
    }

    final egresos = (await _cajas.listarMovimientos(
      tienda,
      desde,
      hasta,
    )).where((m) => !m.esIngreso());
    var gastosNegocio = Decimal.zero;
    var retirosPersonales = Decimal.zero;
    for (final egreso in egresos) {
      if (egreso.esDelNegocio()) {
        gastosNegocio += egreso.getValor();
      } else if (egreso.getClasificacion() ==
          ClasificacionMovimiento.personal) {
        retirosPersonales += egreso.getValor();
      }
    }

    final parcial = await _estadoSincronizacion.hayPendientes(tienda);

    return ReporteDiario(
      dia,
      totalVentas,
      ventasFiadas,
      ventasNequi,
      abonosRecibidos,
      abonosNequi,
      totalEntradas,
      gastosNegocio,
      margen - gastosNegocio,
      retirosPersonales,
      incompleto,
      parcial,
    );
  }

  /// Rotación de cada producto de la tienda en `[desde, hasta)` (RF-11, DA-62,
  /// DA-72). Parte de todos los productos con cero unidades, para que también
  /// aparezcan los que no se vendieron, y suma `salida.calcularUnidades()` de
  /// las salidas vigentes en el producto de la salida (agrupado por id, como en
  /// [calcularMargenes]).
  ///
  /// Ordena de mayor a menor (el empate, por nombre) y reparte en tercios: los
  /// primeros `ceil(n/3)` son ALTA, hasta `ceil(2n/3)` MEDIA y el resto BAJA.
  /// Quien no vendió nada es BAJA aunque su lugar caiga en otro tercio. El mapa
  /// conserva ese orden (DI-40). No se guarda (DA-40).
  Future<Map<Producto, Rotacion>> clasificarRotacion(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async {
    final productos = <String, Producto>{};
    final unidades = <String, Decimal>{};
    for (final item in await _items.listarItems(tienda)) {
      final producto = item.getProducto();
      productos.putIfAbsent(producto.getId(), () => producto);
      unidades.putIfAbsent(producto.getId(), () => Decimal.zero);
    }

    final salidas = await _movimientos.listarSalidasPorTienda(
      tienda,
      desde,
      hasta,
    );
    for (final salida in salidas) {
      final producto = salida.getItem().getProducto();
      final id = producto.getId();
      productos.putIfAbsent(id, () => producto);
      final cantidad = salida.calcularUnidades();
      unidades.update(id, (suma) => suma + cantidad, ifAbsent: () => cantidad);
    }

    final ordenados = unidades.keys.toList()
      ..sort((a, b) {
        final porUnidades = unidades[b]!.compareTo(unidades[a]!);
        if (porUnidades != 0) return porUnidades;
        final porNombre = productos[a]!.getNombre().compareTo(
          productos[b]!.getNombre(),
        );
        return porNombre != 0 ? porNombre : a.compareTo(b);
      });

    final total = ordenados.length;
    final finAlta = (total + 2) ~/ 3;
    final finMedia = (2 * total + 2) ~/ 3;
    return {
      for (var i = 0; i < total; i++)
        productos[ordenados[i]]!: unidades[ordenados[i]]! == Decimal.zero
            ? Rotacion.baja
            : i < finAlta
            ? Rotacion.alta
            : i < finMedia
            ? Rotacion.media
            : Rotacion.baja,
    };
  }
}
