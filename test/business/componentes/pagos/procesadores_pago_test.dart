import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/pagos/procesador_nequi.dart';
import 'package:gip/business/componentes/pagos/procesador_pago_contado.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';

import '../gestion_caja/fakes_caja.dart';

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);

  late CajaRepositorioFalso cajas;
  late ProcesadorPagoContado contado;
  final nequi = ProcesadorNequi();

  final pagoContado = PagoContado('f1', d('50000'), d('18000'));
  final pagoNequi = PagoNequi('f2', d('20000'), null);
  final venta = Venta('v1', [pagoContado], d('32000'), DateTime.utc(2026));

  setUp(() {
    cajas = CajaRepositorioFalso();
    contado = ProcesadorPagoContado(ServicioCaja(cajas));
  });

  test('admite solo su forma de pago', () {
    expect(contado.admite(pagoContado), isTrue);
    expect(contado.admite(pagoNequi), isFalse);
    expect(nequi.admite(pagoNequi), isTrue);
    expect(nequi.admite(pagoContado), isFalse);
  });

  test('contado registra en caja el monto cubierto, no el recibido', () async {
    await contado.procesar(tienda, venta, pagoContado);

    final movs = cajas.movimientosDe(tienda);
    expect(movs, hasLength(1));
    expect(movs.single.getValor(), d('32000'));
    expect(movs.single.getTipo(), TipoMovimientoCaja.ingreso);
    expect(movs.single.getDescripcion(), 'Venta v1');
  });

  test('contado revierte con un EGRESO de ANULACION', () async {
    await contado.revertir(tienda, venta, pagoContado);

    final mov = cajas.movimientosDe(tienda).single;
    expect(mov.getTipo(), TipoMovimientoCaja.egreso);
    expect(mov.getClasificacion(), ClasificacionMovimiento.anulacion);
    expect(mov.getValor(), d('32000'));
  });

  test('Nequi no mueve la caja (DA-63)', () async {
    await nequi.procesar(tienda, venta, pagoNequi);
    await nequi.revertir(tienda, venta, pagoNequi);
    expect(cajas.cajas, isEmpty);
    expect(cajas.movimientos, isEmpty);
  });
}
