import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/surtido/formato_movimiento.dart';

import 'datos_existencias.dart';

void main() {
  final ahora = ahoraExistencias();
  final movimientos = {for (final m in movimientosAceite()) m.getId(): m};

  group('descripcionMovimiento', () {
    test('entrada con factura, venta, conteo y pérdida con motivo', () {
      expect(descripcionMovimiento(movimientos['e-hoy']!), 'Entrada FV-10231');
      expect(descripcionMovimiento(movimientos['s-hoy']!), 'Venta');
      expect(descripcionMovimiento(movimientos['a-ayer']!), 'Conteo');
      expect(
        descripcionMovimiento(movimientos['m-anulada']!),
        'Pérdida (vencido)',
      );
    });

    test('entrada sin factura y devolución al proveedor', () {
      expect(descripcionMovimiento(movimientos['e-vieja']!), 'Entrada');
      expect(
        descripcionMovimiento(
          Merma('m', itemAceite, d('-1'), ahora, MotivoMerma.devueltoProveedor),
        ),
        'Pérdida (devuelto al proveedor)',
      );
    });
  });

  test('cantidadConSigno: + suma, − resta y cero sin signo', () {
    expect(cantidadConSigno(d('24')), '+24');
    expect(cantidadConSigno(d('-1')), '−1');
    expect(cantidadConSigno(d('-0.5')), '−0,5');
    expect(cantidadConSigno(d('0')), '0');
  });

  group('cuandoMovimiento (hora local)', () {
    test('hoy y ayer con la hora', () {
      expect(cuandoMovimiento(noviembre(17, 16, 10), ahora), 'Hoy 4:10 p. m.');
      expect(cuandoMovimiento(noviembre(17, 0, 5), ahora), 'Hoy 12:05 a. m.');
      expect(cuandoMovimiento(noviembre(16, 19, 40), ahora), 'Ayer 7:40 p. m.');
    });

    test('otro día del año con la fecha corta; de otro año, con el año', () {
      expect(cuandoMovimiento(noviembre(9, 8), ahora), '9 nov. 8:00 a. m.');
      expect(
        cuandoMovimiento(DateTime(2025, 12, 31, 12).toUtc(), ahora),
        '31 dic. 2025 12:00 p. m.',
      );
    });
  });

  test('resumenUltimoMovimiento: tipo y cuándo, sin hora si es más viejo', () {
    expect(
      resumenUltimoMovimiento(movimientos['e-hoy']!, ahora),
      'Entrada · hoy 4:10 p. m.',
    );
    expect(
      resumenUltimoMovimiento(movimientos['a-ayer']!, ahora),
      'Conteo · ayer 7:40 p. m.',
    );
    expect(
      resumenUltimoMovimiento(movimientos['m-anulada']!, ahora),
      'Pérdida · 9 nov.',
    );
  });

  test('estadoMovimiento: nada si está vigente', () {
    expect(estadoMovimiento(movimientos['e-hoy']!), isNull);
    expect(estadoMovimiento(movimientos['m-anulada']!), (
      texto: 'Anulado',
      tono: TonoEstado.error,
    ));
    expect(
      estadoMovimiento(
        EntradaMercancia('e', itemAceite, d('1'), ahora, d('1'), null)
          ..setEstado(EstadoMovimiento.enRevision),
      ),
      (texto: 'En revisión', tono: TonoEstado.informativo),
    );
  });
}
