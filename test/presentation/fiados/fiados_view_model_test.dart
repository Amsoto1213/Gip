import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/workflow/pagos/consultar_cliente_coordinator.dart';
import 'package:gip/presentation/fiados/fiados_view_model.dart';
import 'package:mocktail/mocktail.dart';

import 'datos_fiados.dart';

class ConsultarClienteFalso extends Mock
    implements ConsultarClienteCoordinator {}

class _TiendaFalsa extends Fake implements Tienda {}

void main() {
  late DatosFiados datos;
  late FiadosViewModel vm;

  setUpAll(() => registerFallbackValue(_TiendaFalsa()));

  setUp(() async {
    datos = await DatosFiados.crear();
    vm = FiadosViewModel(datos.consultar, tiendaFiados);
  });

  test('carga todos los clientes y resume lo que le deben', () async {
    expect(vm.cargaInicial, isTrue);
    await vm.cargar();

    expect(vm.cargaInicial, isFalse);
    expect(vm.deudaTotal, d('89500')); // 12.500 + 15.000 + 62.000
    expect(vm.deudores, 2);
    expect(vm.saldoDe(datos.maria), d('27500'));
  });

  test('"Deben" oculta a los que están al día y "Todos" los muestra', () async {
    await vm.cargar();
    expect(vm.filtro, FiltroClientes.deben);
    expect(vm.clientes.map((c) => c.getId()), ['c1', 'c2']);

    vm.filtrar(FiltroClientes.todos);
    expect(vm.clientes.map((c) => c.getId()), ['c1', 'c2', 'c3']);
  });

  test('busca sin tildes ni mayúsculas y no cambia el resumen', () async {
    await vm.cargar();
    await vm.buscar('MARIA');
    vm.filtrar(FiltroClientes.todos);

    expect(vm.clientes.map((c) => c.getId()), ['c1']);
    expect(vm.deudaTotal, d('89500'));

    await vm.buscar('zz');
    expect(vm.sinResultados, isTrue);
  });

  test('un fallo de lectura deja el mensaje y no lanza', () async {
    final falso = ConsultarClienteFalso();
    when(() => falso.buscarClientes(any(), any()))
        .thenThrow(StateError('falla'));
    final fallido = FiadosViewModel(falso, tiendaFiados);

    await fallido.cargar();

    expect(fallido.error, FiadosViewModel.mensajeErrorCargar);
    expect(fallido.clientes, isEmpty);
    expect(fallido.sinResultados, isFalse);
  });

  test('elegir guarda el cliente y quita el aviso anterior', () async {
    await vm.cargar();
    vm.avisar('No se pudo registrar el abono. Intente de nuevo');
    expect(vm.aviso, isNotNull);

    vm.elegir(datos.maria);

    expect(vm.elegido, same(datos.maria));
    expect(vm.aviso, isNull);
  });

  test(
    'recargar vuelve a leer al cliente elegido de la base (DI-27)',
    () async {
      await vm.cargar();
      vm.elegir(datos.maria);
      final generacion = vm.generacion;
      // La base devuelve objetos nuevos en cada lectura.
      final deLaBase = Cliente('c1', 'María Pérez', '300 412 4521');
      await datos.clientes.guardar(tiendaFiados, deLaBase);

      await vm.recargar();

      expect(vm.generacion, generacion + 1);
      expect(vm.elegido, same(deLaBase));
      expect(vm.saldoDe(vm.elegido!), Decimal.zero);
    },
  );

  test('recargar sin cliente elegido solo actualiza la lista', () async {
    await vm.cargar();
    await vm.recargar();
    expect(vm.elegido, isNull);
    expect(vm.deudores, 2);
  });
}
