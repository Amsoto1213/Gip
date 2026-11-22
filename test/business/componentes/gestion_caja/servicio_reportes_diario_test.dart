import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_reportes.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/forma_pago.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/pagos/anulacion_venta.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

import '../gestion_inventario/fakes_catalogo.dart';
import '../gestion_inventario/fakes_inventario.dart';
import '../pagos/fakes_pagos.dart';
import 'fakes_caja.dart';

/// generarReporteDiario (CUS-10, RF-09, RF-10, ERS 3.2.4 y 3.2.5).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);

  // Día local 14 de noviembre; ayer y mañana no cuentan.
  final dia = DateTime(2026, 11, 14);
  final manana = DateTime(2026, 11, 15, 8);
  final manana0 = DateTime(2026, 11, 15);
  final ayer = DateTime(2026, 11, 13, 22);
  final temprano = DateTime(2026, 11, 14, 7, 30);
  final tarde = DateTime(2026, 11, 14, 19);

  late VentaRepositorioFalso ventas;
  late MovimientoRepositorioFalso movimientos;
  late CajaRepositorioFalso cajas;
  late FiadoRepositorioFalso fiados;
  late EstadoSincronizacionFalso estado;
  late ServicioReportes servicio;
  late ItemInventario huevo;
  late ItemInventario cafe;

  setUp(() {
    ventas = VentaRepositorioFalso();
    movimientos = MovimientoRepositorioFalso();
    cajas = CajaRepositorioFalso();
    fiados = FiadoRepositorioFalso();
    estado = EstadoSincronizacionFalso();
    servicio = ServicioReportes(
      ventas,
      movimientos,
      cajas,
      fiados,
      estado,
      InventarioRepositorioFalso(),
    );
    huevo = ItemInventario(
      'i1',
      Producto('p1', 'H1', 'Huevo AA', UnidadMedida.unidad, d('400'), d('550')),
      d('100'),
    );
    cafe = ItemInventario(
      'i2',
      Producto('p2', 'C1', 'Café', UnidadMedida.unidad, null, d('8900')),
      d('10'),
    );
  });

  Future<void> vender(
    String id,
    DateTime fecha,
    List<FormaPago> formas,
    String total,
  ) => ventas.guardar(tienda, Venta(id, formas, d(total), fecha));

  Future<void> salida(
    String id,
    ItemInventario item,
    DateTime fecha, {
    required String unidades,
    required String precio,
    String? costo,
  }) => movimientos.guardar(
    tienda,
    SalidaVenta(
      id,
      item,
      -d(unidades),
      fecha,
      'v$id',
      d(precio),
      costo == null ? null : d(costo),
    ),
  );

  Future<void> entrar(String id, DateTime fecha, String cant, String costo) =>
      movimientos.guardar(
        tienda,
        EntradaMercancia(id, huevo, d(cant), fecha, d(costo), null),
      );

  Future<void> moverCaja(
    String id,
    DateTime fecha,
    String valor,
    TipoMovimientoCaja tipo,
    ClasificacionMovimiento clasificacion,
  ) async {
    final caja = Caja('t1_${fecha.day}', DateTime(2026, 11, fecha.day));
    await cajas.crear(tienda, caja);
    await cajas.registrarMovimiento(
      tienda,
      caja,
      MovimientoCaja(id, d(valor), id, clasificacion, tipo, fecha),
    );
  }

  Future<void> abonar(Abono abono) async {
    final fiado = Fiado('fx', d('100000'), dia, Cliente('c1', 'Ana', ''));
    await fiados.registrarAbono(tienda, fiado, abono);
  }

  test('un día con efectivo, Nequi, fiado, abonos y entradas', () async {
    // Venta 1: 20.000 → 12.000 efectivo (paga 15.000, cambio 3.000) y 8.000 Nequi.
    await vender('v1', temprano, [
      contado('p1', '15000', '3000'),
      PagoNequi('p2', d('8000'), 'N1'),
    ], '20000');
    // Venta 2: 10.000 → 4.000 efectivo y 6.000 fiados.
    await vender('v2', tarde, [
      contado('p3', '4000', '0'),
      Fiado('f1', d('6000'), tarde, Cliente('c1', 'Ana', '')),
    ], '10000');
    await salida(
      's1',
      huevo,
      temprano,
      unidades: '10',
      precio: '550',
      costo: '400',
    ); // 1.500
    await salida(
      's2',
      cafe,
      tarde,
      unidades: '2',
      precio: '8900',
      costo: '7000',
    ); // 3.800
    await entrar('e1', temprano, '24', '8600'); // 206.400
    await abonar(Abono('a1', d('5000'), tarde, MedioPago.efectivo, null));
    await abonar(Abono('a2', d('2000'), tarde, MedioPago.nequi, 'R1'));

    final r = await servicio.generarReporteDiario(tienda, dia);

    expect(r.getFecha(), dia);
    expect(r.getTotalVentas(), d('30000'));
    expect(r.getVentasFiadas(), d('6000'));
    expect(r.getVentasNequi(), d('8000'));
    expect(r.getAbonosRecibidos(), d('7000'));
    expect(r.getAbonosNequi(), d('2000'));
    expect(r.calcularDineroNequi(), d('10000'));
    expect(r.getTotalEntradas(), d('206400'));
    expect(r.getGastosNegocio(), Decimal.zero);
    expect(r.getRetirosPersonales(), Decimal.zero);
    expect(r.getUtilidad(), d('5300'));
    expect(r.isIncompleto(), isFalse);
    expect(r.isParcial(), isFalse);
  });

  test('gastos del negocio restan; retiros personales van aparte', () async {
    await salida(
      's1',
      huevo,
      temprano,
      unidades: '10',
      precio: '550',
      costo: '400',
    ); // margen 1.500
    await moverCaja(
      'g1',
      temprano,
      '400',
      TipoMovimientoCaja.egreso,
      ClasificacionMovimiento.negocio,
    );
    await moverCaja(
      'g2',
      tarde,
      '100',
      TipoMovimientoCaja.egreso,
      ClasificacionMovimiento.negocio,
    );
    await moverCaja(
      'r1',
      tarde,
      '5000',
      TipoMovimientoCaja.egreso,
      ClasificacionMovimiento.personal,
    );
    // Devolución por anulación: no es gasto ni retiro.
    await moverCaja(
      'x1',
      tarde,
      '7000',
      TipoMovimientoCaja.egreso,
      ClasificacionMovimiento.anulacion,
    );
    // Los ingresos no son egresos.
    await moverCaja(
      'i1',
      tarde,
      '9000',
      TipoMovimientoCaja.ingreso,
      ClasificacionMovimiento.negocio,
    );

    final r = await servicio.generarReporteDiario(tienda, dia);

    expect(r.getGastosNegocio(), d('500'));
    expect(r.getRetirosPersonales(), d('5000'));
    expect(r.getUtilidad(), d('1000'));
  });

  test('un día sin datos da todo en cero', () async {
    final r = await servicio.generarReporteDiario(tienda, dia);

    expect(r.getTotalVentas(), Decimal.zero);
    expect(r.getVentasFiadas(), Decimal.zero);
    expect(r.getVentasNequi(), Decimal.zero);
    expect(r.getAbonosRecibidos(), Decimal.zero);
    expect(r.getAbonosNequi(), Decimal.zero);
    expect(r.calcularDineroNequi(), Decimal.zero);
    expect(r.getTotalEntradas(), Decimal.zero);
    expect(r.getGastosNegocio(), Decimal.zero);
    expect(r.getRetirosPersonales(), Decimal.zero);
    expect(r.getUtilidad(), Decimal.zero);
    expect(r.isIncompleto(), isFalse);
    expect(r.isParcial(), isFalse);
  });

  test('lo de otros días no cuenta, y el fin del día no se incluye', () async {
    for (final fecha in [ayer, manana0, manana]) {
      await vender('v${fecha.day}${fecha.hour}', fecha, [
        contado('p${fecha.hour}', '1000'),
      ], '1000');
      await salida(
        's${fecha.day}${fecha.hour}',
        huevo,
        fecha,
        unidades: '1',
        precio: '550',
        costo: '400',
      );
      await entrar('e${fecha.day}${fecha.hour}', fecha, '1', '100');
      await abonar(
        Abono(
          'a${fecha.day}${fecha.hour}',
          d('300'),
          fecha,
          MedioPago.nequi,
          null,
        ),
      );
      await moverCaja(
        'm${fecha.day}${fecha.hour}',
        fecha,
        '50',
        TipoMovimientoCaja.egreso,
        ClasificacionMovimiento.negocio,
      );
    }
    // Una venta a las 00:00 del día mismo sí cuenta (el inicio se incluye).
    await vender('vhoy', dia, [contado('phoy', '2000')], '2000');

    final r = await servicio.generarReporteDiario(tienda, dia);

    expect(r.getTotalVentas(), d('2000'));
    expect(r.getTotalEntradas(), Decimal.zero);
    expect(r.getAbonosRecibidos(), Decimal.zero);
    expect(r.getGastosNegocio(), Decimal.zero);
    expect(r.getUtilidad(), Decimal.zero);
  });

  test('un abono anulado no suma', () async {
    await abonar(Abono('a1', d('5000'), tarde, MedioPago.nequi, null));
    await abonar(
      Abono('a2', d('3000'), tarde, MedioPago.nequi, null, anulado: true),
    );

    final r = await servicio.generarReporteDiario(tienda, dia);

    expect(r.getAbonosRecibidos(), d('5000'));
    expect(r.getAbonosNequi(), d('5000'));
  });

  test('una salida sin costo deja el reporte incompleto', () async {
    await salida(
      's1',
      huevo,
      temprano,
      unidades: '10',
      precio: '550',
      costo: '400',
    ); // 1.500
    await salida('s2', cafe, tarde, unidades: '2', precio: '8900'); // sin costo

    final r = await servicio.generarReporteDiario(tienda, dia);

    expect(r.isIncompleto(), isTrue);
    // Solo suma el margen de la salida que sí tiene costo.
    expect(r.getUtilidad(), d('1500'));
  });

  test('es parcial si quedan cambios sin subir al servidor', () async {
    estado.pendientes = true;

    final r = await servicio.generarReporteDiario(tienda, dia);

    expect(r.isParcial(), isTrue);
  });

  test('la hora de la fecha no importa: es el día completo', () async {
    await vender('v1', temprano, [contado('p1', '1000')], '1000');

    final r = await servicio.generarReporteDiario(
      tienda,
      DateTime(2026, 11, 14, 23, 59),
    );

    expect(r.getTotalVentas(), d('1000'));
    expect(r.getFecha(), dia);
  });

  test('las ventas anuladas no cuentan (CUS-20)', () async {
    await vender('v1', temprano, [
      PagoContado('p1', d('5000'), d('0')),
    ], '5000');
    await ventas.guardar(
      tienda,
      Venta(
        'v2',
        [PagoNequi('p2', d('3000'), null)],
        d('3000'),
        tarde,
        anulacion: AnulacionVenta(
          'a1',
          Administrador('u1', 'Carmen', '1'),
          tarde,
          'Error al cobrar',
        ),
      ),
    );

    final r = await servicio.generarReporteDiario(tienda, dia);

    expect(r.getTotalVentas(), d('5000'));
    expect(r.getVentasNequi(), Decimal.zero);
  });
}

PagoContado contado(String id, String recibido, [String cambio = '0']) =>
    PagoContado(id, Decimal.parse(recibido), Decimal.parse(cambio));
