import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/presentation/fiados/abono_view_model.dart';

import 'datos_fiados.dart';

void main() {
  late DatosFiados datos;

  setUp(() async => datos = await DatosFiados.crear());

  AbonoViewModel crear([Cliente? cliente]) =>
      AbonoViewModel(datos.abonar, tiendaFiados, cliente ?? datos.maria);

  const mensajeMonto =
      'El abono debe ser mayor que cero y no puede superar el saldo pendiente';

  test('lista los fiados pendientes del más antiguo al más reciente y no '
      'elige ninguno si hay varios', () {
    final vm = crear();
    expect(vm.fiados.map((f) => f.getId()), ['f1', 'f2']);
    expect(vm.fiado, isNull);
    expect(vm.medio, MedioPago.efectivo);
  });

  test('con un solo fiado pendiente lo elige y sugiere su saldo', () async {
    final jose = (await datos.consultar.buscarClientes(
      tiendaFiados,
      'jose',
    )).single;
    final vm = crear(jose);
    expect(vm.fiado!.getId(), 'f3');
    expect(vm.montoTexto, '62.000');
  });

  test('elegir un fiado sugiere su saldo como monto', () {
    final vm = crear()..elegirFiado(datos.fiadoViejo);
    expect(vm.montoTexto, '12.500');
    expect(vm.monto, d('12500'));
    expect(vm.quedaSaldado, isTrue);
    expect(vm.montoParaBoton, d('12500'));
  });

  test('un monto menor al saldo no lo salda', () {
    final vm = crear()
      ..elegirFiado(datos.fiadoViejo)
      ..cambiarMonto('5.000');
    expect(vm.quedaSaldado, isFalse);
    expect(vm.errorMonto, isNull);
    expect(vm.montoParaBoton, d('5000'));
  });

  for (final texto in ['0', '12.501', 'abc']) {
    test('monto "$texto": error "Monto no válido" mientras se escribe', () {
      final vm = crear()
        ..elegirFiado(datos.fiadoViejo)
        ..cambiarMonto(texto);
      expect(vm.errorMonto, mensajeMonto);
      expect(vm.montoParaBoton, isNull);
      expect(vm.quedaSaldado, isFalse);
    });
  }

  test(
    'registrar sin elegir fiado pide elegir y no llama al servicio',
    () async {
      final vm = crear();
      expect(vm.errorFiado, isNull);

      expect(await vm.registrar(), isFalse);

      expect(vm.errorFiado, 'Elija a cuál fiado abona');
      expect(datos.fiados.abonos, isEmpty);
    },
  );

  test(
    'registrar con monto no válido no toca el fiado ni pide recargar',
    () async {
      final vm = crear()
        ..elegirFiado(datos.fiadoViejo)
        ..cambiarMonto('99.999');

      expect(await vm.registrar(), isFalse);

      expect(vm.errorMonto, mensajeMonto);
      expect(vm.debeRecargar, isFalse);
      expect(datos.fiadoViejo.getSaldoPendiente(), d('12500'));
      expect(datos.fiados.abonos, isEmpty);
    },
  );

  test('registrar con monto vacío muestra el error de monto', () async {
    final vm = crear()
      ..elegirFiado(datos.fiadoViejo)
      ..cambiarMonto('');
    expect(vm.errorMonto, isNull);

    expect(await vm.registrar(), isFalse);

    expect(vm.errorMonto, mensajeMonto);
  });

  test('abono en efectivo: baja el saldo, entra a la caja y deja el nuevo '
      'saldo', () async {
    final vm = crear()
      ..elegirFiado(datos.fiadoViejo)
      ..cambiarMonto('10.000');

    expect(await vm.registrar(), isTrue);

    expect(vm.saldoNuevo, d('2500'));
    expect(datos.fiadoViejo.getSaldoPendiente(), d('2500'));
    expect(vm.error, isNull);
    expect(vm.debeRecargar, isFalse);
    expect(
      datos.cajas.movimientosDe(tiendaFiados).single.getValor(),
      d('10000'),
    );
  });

  test('abono por Nequi: guarda la referencia y no toca la caja', () async {
    final vm = crear()
      ..elegirFiado(datos.fiadoNuevo)
      ..elegirMedio(MedioPago.nequi)
      ..cambiarReferencia(' N-77 ');

    expect(await vm.registrar(), isTrue);

    final abono = datos.fiados.abonos.single;
    expect(abono.getMedio(), MedioPago.nequi);
    expect(abono.getReferencia(), 'N-77');
    expect(datos.fiadoNuevo.getEstado(), EstadoFiado.saldado);
    expect(datos.cajas.movimientosDe(tiendaFiados), isEmpty);
  });

  test('con efectivo la referencia escrita antes se ignora', () async {
    final vm = crear()
      ..elegirFiado(datos.fiadoNuevo)
      ..elegirMedio(MedioPago.nequi)
      ..cambiarReferencia('N-77')
      ..elegirMedio(MedioPago.efectivo);

    expect(await vm.registrar(), isTrue);

    expect(datos.fiados.abonos.single.getReferencia(), isNull);
  });

  test('si falla el guardado muestra el error y pide volver a leer al '
      'cliente (DI-27)', () async {
    datos.fiados.fallar = true;
    final vm = crear()
      ..elegirFiado(datos.fiadoViejo)
      ..cambiarMonto('10.000');

    expect(await vm.registrar(), isFalse);

    expect(vm.error, AbonoViewModel.mensajeErrorRegistrar);
    expect(vm.debeRecargar, isTrue);
    expect(vm.registrando, isFalse);
    expect(datos.fiados.abonos, isEmpty);
  });

  test('si la caja está cerrada muestra su mensaje y pide recargar', () async {
    datos.cajas.fallar = true;
    final vm = crear()..elegirFiado(datos.fiadoViejo);

    expect(await vm.registrar(), isFalse);

    expect(vm.error, AbonoViewModel.mensajeErrorRegistrar);
    expect(vm.debeRecargar, isTrue);
    expect(datos.cajas.movimientosDe(tiendaFiados), isEmpty);
    expect(datos.fiados.abonos, isEmpty);
  });
}
