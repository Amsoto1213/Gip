import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/anulacion_venta.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';

/// Anulación de ventas y de fiados (CUS-20, RNF-15, DA-51).
void main() {
  Decimal d(String v) => Decimal.parse(v);
  final fecha = DateTime.utc(2026, 11, 15, 15);
  final propietario = Administrador('u1', 'Carmen Ruiz', '1000000001');

  AnulacionVenta anulacion([String motivo = 'Error al cobrar']) =>
      AnulacionVenta('a1', propietario, fecha, motivo);

  Venta venta() =>
      Venta('v1', [PagoContado('p1', d('5000'), d('0'))], d('5000'), fecha);

  group('AnulacionVenta', () {
    test('guarda quién, cuándo y por qué', () {
      final a = anulacion('Cliente devolvió');

      expect(a.getId(), 'a1');
      expect(a.getUsuario(), same(propietario));
      expect(a.getFecha(), fecha);
      expect(a.getMotivo(), 'Cliente devolvió');
    });
  });

  group('Venta.anular', () {
    test('una venta nueva está vigente', () {
      final v = venta();
      expect(v.isAnulada(), isFalse);
      expect(v.getAnulacion(), isNull);
    });

    test('guarda la anulación y no cambia sus datos', () {
      final v = venta();
      final a = anulacion();

      v.anular(a);

      expect(v.isAnulada(), isTrue);
      expect(v.getAnulacion(), same(a));
      expect(v.getTotal(), d('5000'));
      expect(v.getFecha(), fecha);
      expect(v.getFormasPago(), hasLength(1));
    });

    test('rechaza una segunda anulación y conserva la primera', () {
      final v = venta();
      final primera = anulacion('Error al cobrar');
      v.anular(primera);

      expect(
        () => v.anular(anulacion('Otra')),
        throwsA(
          isA<ExcepcionVentaYaAnulada>().having(
            (e) => e.mensaje,
            'mensaje',
            'La venta ya estaba anulada',
          ),
        ),
      );
      expect(v.getAnulacion(), same(primera));
    });

    test('una venta leída ya anulada nace anulada', () {
      final v = Venta('v2', const [], d('1'), fecha, anulacion: anulacion());

      expect(v.isAnulada(), isTrue);
      expect(
        () => v.anular(anulacion()),
        throwsA(isA<ExcepcionVentaYaAnulada>()),
      );
    });
  });

  group('Fiado.anular', () {
    Fiado fiado() => Fiado('f1', d('8400'), fecha, Cliente('c1', 'Ana', ''));

    test('sin abonos: saldo cero y estado ANULADO', () {
      final f = fiado()..anular();

      expect(f.getSaldoPendiente(), Decimal.zero);
      expect(f.getEstado(), EstadoFiado.anulado);
      expect(f.getMontoInicial(), d('8400'));
    });

    test('con abonos se rechaza y no cambia nada', () {
      final f = fiado()
        ..registrarAbono(
          Abono('a1', d('1000'), fecha, MedioPago.efectivo, null),
        );

      expect(
        () => f.anular(),
        throwsA(
          isA<ExcepcionFiadoConAbonos>().having(
            (e) => e.mensaje,
            'mensaje',
            'No se puede anular la venta: el fiado ya tiene abonos',
          ),
        ),
      );
      expect(f.getSaldoPendiente(), d('7400'));
      expect(f.getEstado(), EstadoFiado.pendiente);
    });

    test('restaurar devuelve el saldo y el estado que tenía', () {
      final f = fiado();
      final saldo = f.getSaldoPendiente();
      final estado = f.getEstado();
      f.anular();

      f.restaurar(saldo, estado);

      expect(f.getSaldoPendiente(), d('8400'));
      expect(f.getEstado(), EstadoFiado.pendiente);
    });
  });
}
