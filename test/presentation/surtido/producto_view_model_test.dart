import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/gestionar_producto_coordinator.dart';
import 'package:gip/presentation/surtido/producto_view_model.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';
import 'package:mocktail/mocktail.dart';

class GestionarProductoFalso extends Mock
    implements GestionarProductoCoordinator {}

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final galletas = Producto(
    'p1',
    'GAL-6',
    'Galletas',
    UnidadMedida.unidad,
    null,
    Decimal.parse('3500'),
  );

  late GestionarProductoFalso coordinator;

  setUpAll(() {
    registerFallbackValue(tienda);
    registerFallbackValue(galletas);
    registerFallbackValue(UnidadMedida.unidad);
    registerFallbackValue(Decimal.zero);
  });

  setUp(() => coordinator = GestionarProductoFalso());

  Future<void> guardar(
    ProductoViewModel vm, {
    String venta = '3.500',
    String compra = '',
  }) => vm.guardar(
    codigo: 'GAL-6',
    nombre: 'Galletas',
    unidad: UnidadMedida.unidad,
    precioVenta: venta,
    precioCompra: compra,
  );

  group('leerPrecio', () {
    test('entiende miles con punto, decimales con coma y el signo \$', () {
      expect(ProductoViewModel.leerPrecio(r'$ 3.500'), Decimal.parse('3500'));
      expect(ProductoViewModel.leerPrecio('2.600,50'), Decimal.parse('2600.5'));
      expect(ProductoViewModel.leerPrecio('0'), Decimal.zero);
      expect(ProductoViewModel.leerPrecio('-5'), Decimal.parse('-5'));
    });

    test('devuelve null si no es un número', () {
      expect(ProductoViewModel.leerPrecio(''), isNull);
      expect(ProductoViewModel.leerPrecio('abc'), isNull);
      expect(ProductoViewModel.leerPrecio('1,2,3'), isNull);
    });
  });

  test('crea, avisa "Producto creado" y queda en modo edición', () async {
    when(
      () => coordinator.crearProducto(any(), any(), any(), any(), any(), any()),
    ).thenAnswer((_) async => galletas);
    final vm = ProductoViewModel(coordinator, tienda);
    expect(vm.esNuevo, isTrue);

    await guardar(vm, compra: '2.600');

    verify(
      () => coordinator.crearProducto(
        tienda,
        'GAL-6',
        'Galletas',
        UnidadMedida.unidad,
        Decimal.parse('2600'),
        Decimal.parse('3500'),
      ),
    ).called(1);
    expect(vm.aviso, 'Producto creado');
    expect(vm.error, isNull);
    expect(vm.esNuevo, isFalse);
    expect(vm.producto, galletas);
  });

  test('el costo vacío se envía nulo', () async {
    when(
      () => coordinator.crearProducto(any(), any(), any(), any(), any(), any()),
    ).thenAnswer((_) async => galletas);
    await guardar(ProductoViewModel(coordinator, tienda));

    verify(
      () => coordinator.crearProducto(
        any(),
        any(),
        any(),
        any(),
        null,
        Decimal.parse('3500'),
      ),
    ).called(1);
  });

  test('con producto edita y avisa "Producto actualizado"', () async {
    when(
      () =>
          coordinator.editarProducto(any(), any(), any(), any(), any(), any()),
    ).thenAnswer((_) async {});
    final vm = ProductoViewModel(coordinator, tienda, producto: galletas);

    await guardar(vm, venta: '4.000');

    verify(
      () => coordinator.editarProducto(
        tienda,
        galletas,
        'Galletas',
        UnidadMedida.unidad,
        null,
        Decimal.parse('4000'),
      ),
    ).called(1);
    verifyNever(
      () => coordinator.crearProducto(any(), any(), any(), any(), any(), any()),
    );
    expect(vm.aviso, 'Producto actualizado');
  });

  test('muestra el mensaje del negocio tal cual', () async {
    when(
      () => coordinator.crearProducto(any(), any(), any(), any(), any(), any()),
    ).thenThrow(const ExcepcionDatosProductoNoValidos.alCrear());
    final vm = ProductoViewModel(coordinator, tienda);

    await guardar(vm);

    expect(vm.error, 'El código interno ya existe o faltan datos válidos');
    expect(vm.aviso, isNull);
    expect(vm.esNuevo, isTrue);
    expect(vm.guardando, isFalse);
  });

  test('pide el precio de venta sin llamar al coordinador', () async {
    final vm = ProductoViewModel(coordinator, tienda);
    await guardar(vm, venta: '  ');
    expect(vm.error, 'Escribe el precio de venta');
    verifyZeroInteractions(coordinator);
  });

  test('rechaza un costo que no es número sin llamar al coordinador', () async {
    final vm = ProductoViewModel(coordinator, tienda);
    await guardar(vm, compra: 'dos mil');
    expect(vm.error, 'Escribe un costo válido o déjalo vacío');
    verifyZeroInteractions(coordinator);
  });

  test('un error inesperado muestra un mensaje genérico', () async {
    when(
      () => coordinator.crearProducto(any(), any(), any(), any(), any(), any()),
    ).thenThrow(StateError('disco lleno'));
    final vm = ProductoViewModel(coordinator, tienda);

    await guardar(vm);

    expect(vm.error, 'No se pudo guardar el producto. Inténtalo de nuevo');
  });
}
