import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
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

  group('códigos (CUS-17, CUS-18 Asociar código)', () {
    CodigoProducto ean() =>
        CodigoProducto('c1', FormatoCodigo.ean13, '7701234567897');

    test('asocia el código al producto guardado', () async {
      final producto = Producto(
        'p9',
        'LEC-1',
        'Leche',
        UnidadMedida.unidad,
        null,
        Decimal.parse('4200'),
      );
      when(() => coordinator.asociarCodigo(tienda, producto, '7701234567897'))
          .thenAnswer((_) async {
            final c = ean();
            producto.agregarCodigo(c);
            return c;
          });
      final vm = ProductoViewModel(coordinator, tienda, producto: producto);

      await vm.asociarCodigo('7701234567897');

      expect(vm.aviso, 'Código asociado');
      expect(vm.error, isNull);
      expect(vm.codigos.map((c) => c.getValor()), ['7701234567897']);
      expect(vm.guardando, isFalse);
    });

    test('muestra el rechazo del código repetido (paso 25)', () async {
      when(() => coordinator.asociarCodigo(any(), any(), any()))
          .thenThrow(const ExcepcionCodigoRepetido());
      final vm = ProductoViewModel(coordinator, tienda, producto: galletas);

      await vm.asociarCodigo('7701234567897');

      expect(vm.error, 'Ese código ya está asociado a otro producto');
      expect(vm.aviso, isNull);
    });

    test('un error inesperado muestra un mensaje para el tendero', () async {
      when(() => coordinator.asociarCodigo(any(), any(), any()))
          .thenThrow(StateError('disco'));
      final vm = ProductoViewModel(coordinator, tienda, producto: galletas);

      await vm.asociarCodigo('7701234567897');

      expect(vm.error, 'No se pudo asociar el código. Inténtalo de nuevo');
    });

    test('en un producto nuevo el código queda pendiente', () async {
      final vm = ProductoViewModel(coordinator, tienda);

      await vm.asociarCodigo(' 7701234567897 ');

      expect(vm.codigoPendiente, '7701234567897');
      verifyNever(() => coordinator.asociarCodigo(any(), any(), any()));
    });

    test('en un producto nuevo rechaza el código vacío', () async {
      final vm = ProductoViewModel(coordinator, tienda);

      await vm.asociarCodigo('  ');

      expect(vm.error, 'Escriba o lea el código');
      expect(vm.codigoPendiente, isNull);
    });

    test('el código leído en Buscar queda pendiente y se puede descartar', () {
      final vm = ProductoViewModel(
        coordinator,
        tienda,
        codigoLeido: '7701234567897',
      );
      expect(vm.codigoPendiente, '7701234567897');

      vm.descartarCodigoPendiente();
      expect(vm.codigoPendiente, isNull);
    });

    test('al editar no hay código pendiente aunque llegue uno', () {
      final vm = ProductoViewModel(
        coordinator,
        tienda,
        producto: galletas,
        codigoLeido: '7701234567897',
      );
      expect(vm.codigoPendiente, isNull);
    });

    test('al crear asocia el código pendiente', () async {
      when(
        () =>
            coordinator.crearProducto(any(), any(), any(), any(), any(), any()),
      ).thenAnswer((_) async => galletas);
      when(() => coordinator.asociarCodigo(tienda, galletas, '7701234567897'))
          .thenAnswer((_) async => ean());
      final vm = ProductoViewModel(
        coordinator,
        tienda,
        codigoLeido: '7701234567897',
      );

      await guardar(vm);

      expect(vm.aviso, 'Producto creado. Código asociado');
      expect(vm.codigoPendiente, isNull);
      expect(vm.esNuevo, isFalse);
    });

    test('si el código pendiente falla, el producto queda creado', () async {
      when(
        () =>
            coordinator.crearProducto(any(), any(), any(), any(), any(), any()),
      ).thenAnswer((_) async => galletas);
      when(() => coordinator.asociarCodigo(any(), any(), any()))
          .thenThrow(const ExcepcionCodigoRepetido());
      final vm = ProductoViewModel(
        coordinator,
        tienda,
        codigoLeido: '7701234567897',
      );

      await guardar(vm);

      expect(vm.aviso, 'Producto creado');
      expect(vm.error, 'Ese código ya está asociado a otro producto');
      expect(vm.producto, galletas);
      expect(vm.codigoPendiente, isNull);
    });

    test('si crear falla, el código sigue pendiente', () async {
      when(
        () =>
            coordinator.crearProducto(any(), any(), any(), any(), any(), any()),
      ).thenThrow(const ExcepcionDatosProductoNoValidos.alCrear());
      final vm = ProductoViewModel(
        coordinator,
        tienda,
        codigoLeido: '7701234567897',
      );

      await guardar(vm);

      expect(vm.codigoPendiente, '7701234567897');
      verifyNever(() => coordinator.asociarCodigo(any(), any(), any()));
    });
  });
}
