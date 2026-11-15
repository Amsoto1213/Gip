import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_inventario/estrategia_consumo.dart';
import 'package:gip/business/entidades/gestion_inventario/alerta_reabastecimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_alerta_repositorio.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_inventario_repositorio.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_venta_perdida_repositorio.dart';
import 'package:uuid/uuid.dart';

/// Pure Fabrication e Information Expert de la demanda: calcula y guarda las
/// alertas de su tienda una vez al día dentro de la app (CUS-24; RF-05, RD-11,
/// DA-35) y las entrega a la consulta del Propietario (CUS-05).
///
/// `registrarVentaPerdida` llega con CUS-13 (DI-25).
class ServicioAlertas {
  ServicioAlertas(
    this._items,
    this._movimientos,
    this._ventasPerdidas,
    this._alertas,
    this._estrategiaConsumo,
    this._umbralDiasCobertura,
  );

  /// Días hacia atrás del periodo de consumo; con menos días de historial la
  /// alerta es provisional (RNF-03).
  static const diasPeriodo = 30;

  final IInventarioRepositorio _items;
  final IMovimientoInventarioRepositorio _movimientos;
  final IVentaPerdidaRepositorio _ventasPerdidas;
  final IAlertaRepositorio _alertas;
  final EstrategiaConsumo _estrategiaConsumo;
  final int _umbralDiasCobertura;

  /// Evalúa cada ítem de la tienda y guarda las alertas del día con
  /// alertas.reemplazar, que descarta las anteriores de esa fecha (RD-11,
  /// DA-35). [fecha] se toma como día local, sin hora (DI-25).
  Future<List<AlertaReabastecimiento>> generarAlertas(
    Tienda tienda,
    DateTime fecha,
  ) async {
    final dia = diaLocal(fecha);
    final items = await _items.listarItems(tienda);
    final alertas = <AlertaReabastecimiento>[];
    for (final item in items) {
      final alerta = await _evaluarItem(item, dia);
      if (alerta != null) alertas.add(alerta);
    }
    await _alertas.reemplazar(tienda, dia, alertas);
    return alertas;
  }

  /// Periodo `[dia − 30 días, dia)`: los 30 días completos anteriores, sin el
  /// día en curso (DI-25). Los días con datos van desde el primer registro del
  /// ítem (movimiento o venta perdida) hasta [dia], con tope de 30; con menos
  /// de 30 la alerta es provisional (RNF-03). Sin consumo no hay alerta
  /// (RF-05); si no, diasCobertura = existencia / consumo y hay alerta cuando
  /// es menor que el umbral. Con existencia cero o negativa la cobertura es
  /// cero. Guarda la existencia del momento (RNF-02).
  Future<AlertaReabastecimiento?> _evaluarItem(
    ItemInventario item,
    DateTime dia,
  ) async {
    final desde = DateTime(dia.year, dia.month, dia.day - diasPeriodo);
    final salidas = await _movimientos.listarSalidas(item, desde, dia);
    final perdidas = await _ventasPerdidas.listarPorProducto(
      item.getProducto(),
      desde,
      dia,
    );
    final diasHistoria = await _diasDeHistoria(item, perdidas, dia);
    final consumo = _estrategiaConsumo.calcularConsumoDiario(
      salidas,
      perdidas,
      math.min(diasHistoria, diasPeriodo),
    );
    if (consumo <= Decimal.zero) return null;

    final stock = item.getStockActual();
    final cobertura = stock <= Decimal.zero
        ? Decimal.zero
        : (stock / consumo).toDecimal(scaleOnInfinitePrecision: 10);
    if (cobertura >= Decimal.fromInt(_umbralDiasCobertura)) return null;

    return AlertaReabastecimiento(
      const Uuid().v4(),
      item,
      dia,
      stock,
      consumo,
      cobertura.round(scale: 2),
      diasHistoria < diasPeriodo,
    );
  }

  /// Días calendario entre el primer registro del ítem y [dia].
  Future<int> _diasDeHistoria(
    ItemInventario item,
    List<VentaPerdida> perdidas,
    DateTime dia,
  ) async {
    final primerMovimiento = await _movimientos.buscarFechaPrimerMovimiento(
      item,
    );
    final fechas = [?primerMovimiento, ...perdidas.map((p) => p.getFecha())];
    if (fechas.isEmpty) return 0;
    final primera = fechas.reduce((a, b) => a.isBefore(b) ? a : b);
    return _diasEntre(diaLocal(primera), dia);
  }

  /// Alertas ya calculadas de la fecha (RD-09); lectura rápida.
  Future<List<AlertaReabastecimiento>> obtenerAlertas(
    Tienda tienda,
    DateTime fecha,
  ) => _alertas.listarPorFecha(tienda, diaLocal(fecha));

  /// Ventas perdidas de la tienda en el periodo (RF-12).
  Future<List<VentaPerdida>> obtenerVentasPerdidas(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) => _ventasPerdidas.buscarPorPeriodo(tienda, desde, hasta);

  /// Día local sin hora del momento dado.
  static DateTime diaLocal(DateTime momento) {
    final local = momento.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Días calendario de [desde] a [hasta], sin que el horario de verano los
  /// altere.
  static int _diasEntre(DateTime desde, DateTime hasta) => DateTime.utc(
    hasta.year,
    hasta.month,
    hasta.day,
  ).difference(DateTime.utc(desde.year, desde.month, desde.day)).inDays;
}
