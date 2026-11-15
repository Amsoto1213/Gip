import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';

void main() {
  Decimal d(String v) => Decimal.parse(v);
  final fecha = DateTime.utc(2026, 11, 15);

  group('Fiado', () {
    test('nace con saldo = monto y estado PENDIENTE', () {
      final cliente = Cliente('c1', 'María Pérez', '3004124521');
      final fiado = Fiado('f1', d('8400'), fecha, cliente);
      expect(fiado.getSaldoPendiente(), d('8400'));
      expect(fiado.getEstado(), EstadoFiado.pendiente);
      expect(fiado.getCliente(), same(cliente));
    });

    test('cubre de la venta su monto inicial (DA-72)', () {
      final fiado = Fiado('f1', d('8400'), fecha, Cliente('c1', 'Ana', ''));
      expect(fiado.calcularMontoCubierto(), d('8400'));
    });
  });

  group('Cliente', () {
    test('sin fiados: saldo cero y sin pendientes', () {
      final cliente = Cliente('c1', 'Ana', '');
      expect(cliente.calcularSaldoPendiente(), Decimal.zero);
      expect(cliente.obtenerFiadosPendientes(), isEmpty);
    });

    test('suma el saldo solo de los fiados pendientes', () {
      final cliente = Cliente('c1', 'María Pérez', '');
      cliente
        ..agregarFiado(Fiado('f1', d('20000'), fecha, cliente))
        ..agregarFiado(
          Fiado.guardado(
            'f2',
            d('30000'),
            fecha,
            cliente,
            d('27500'),
            EstadoFiado.pendiente,
          ),
        )
        ..agregarFiado(
          Fiado.guardado(
            'f3',
            d('5000'),
            fecha,
            cliente,
            Decimal.zero,
            EstadoFiado.saldado,
          ),
        );
      expect(cliente.obtenerFiadosPendientes(), hasLength(2));
      expect(cliente.calcularSaldoPendiente(), d('47500'));
    });

    test('la lista de pendientes no se modifica desde afuera', () {
      final cliente = Cliente('c1', 'Ana', '');
      expect(
        () => cliente.obtenerFiadosPendientes().add(
          Fiado('f1', d('1'), fecha, cliente),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
