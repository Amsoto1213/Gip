import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/interprete_codigo.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_catalogo.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_impresion_etiquetas.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_movimiento_inventario_repositorio.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';
import 'package:mocktail/mocktail.dart';

import 'fakes_catalogo.dart';

class InterpreteFalso extends Mock implements InterpreteCodigo {}

class ImpresionFalsa extends Mock implements IImpresionEtiquetas {}

class MovimientosFalsos extends Mock
    implements IMovimientoInventarioRepositorio {}

void main() {
  final tienda = Tienda(
    '11111111-1111-4111-8111-111111111111',
    'T001',
    'Granero El Porvenir',
    'Arjona, Bolívar',
  );
  final otraTienda = Tienda(
    '33333333-3333-4333-8333-333333333333',
    'T002',
    'Tienda La Esquina',
    'Turbaco, Bolívar',
  );
  final uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  late ProductoRepositorioFalso productos;
  late InventarioRepositorioFalso items;
  late UnidadTrabajoFalsa unidad;
  late InterpreteFalso interprete;
  late ImpresionFalsa impresion;
  late MovimientosFalsos movimientos;
  late ServicioCatalogo servicio;

  setUp(() {
    productos = ProductoRepositorioFalso();
    items = InventarioRepositorioFalso();
    unidad = UnidadTrabajoFalsa([productos, items]);
    productos.unidad = unidad;
    items.unidad = unidad;
    interprete = InterpreteFalso();
    impresion = ImpresionFalsa();
    movimientos = MovimientosFalsos();
    final servicioInventario = ServicioInventario(
      items,
      movimientos,
      Decimal.fromInt(5),
      unidad,
      productos,
    );
    servicio = ServicioCatalogo(
      productos,
      [interprete],
      servicioInventario,
      impresion,
      unidad,
    );
  });

  /// Las piezas pendientes (DI-15) no se llaman en ningún flujo de CUS-18.
  void verificarPiezasPendientesSinUso() {
    verifyZeroInteractions(interprete);
    verifyZeroInteractions(impresion);
    verifyZeroInteractions(movimientos);
  }

  Future<Producto> crearGalletas({
    String codigo = 'GAL-6',
    Decimal? precioCompra,
  }) => servicio.crearProducto(
    tienda,
    codigo,
    'Galletas de coco x 6',
    UnidadMedida.unidad,
    precioCompra ?? Decimal.parse('2600'),
    Decimal.parse('3500'),
  );

  Matcher errorAlCrear() => throwsA(
    isA<ExcepcionDatosProductoNoValidos>().having(
      (e) => e.mensaje,
      'mensaje',
      'El código interno ya existe o faltan datos válidos',
    ),
  );

  Matcher errorAlEditar() => throwsA(
    isA<ExcepcionDatosProductoNoValidos>().having(
      (e) => e.mensaje,
      'mensaje',
      'Faltan datos válidos del producto',
    ),
  );

  group('crearProducto', () {
    test('crea el producto con id UUID v4 y sus datos', () async {
      final producto = await crearGalletas();

      expect(producto.getId(), matches(uuidV4));
      expect(producto.getCodigo(), 'GAL-6');
      expect(producto.getNombre(), 'Galletas de coco x 6');
      expect(producto.getUnidadMedida(), UnidadMedida.unidad);
      expect(producto.getPrecioCompra(), Decimal.parse('2600'));
      expect(producto.getPrecioVenta(), Decimal.parse('3500'));
      expect(await productos.buscarPorId(tienda, producto.getId()), producto);
      verificarPiezasPendientesSinUso();
    });

    test('crea su ItemInventario con stock cero', () async {
      final producto = await crearGalletas();

      final item = await items.buscarItem(tienda, producto);
      expect(item, isNotNull);
      expect(item!.getId(), matches(uuidV4));
      expect(item.getId(), isNot(producto.getId()));
      expect(item.getStockActual(), Decimal.zero);
    });

    test(
      'guarda el producto y el ítem en una sola transacción (RNF-04)',
      () async {
        await crearGalletas();

        expect(unidad.transacciones, 1);
        expect(productos.guardadosEnTransaccion, [true]);
        expect(items.guardadosEnTransaccion, [true]);
      },
    );

    test('si falla el ítem, no queda guardado el producto', () async {
      items.fallar = true;

      await expectLater(crearGalletas(), throwsStateError);

      expect(await productos.listar(tienda), isEmpty);
      expect(await items.listarItems(tienda), isEmpty);
    });

    test('quita los espacios del código y del nombre', () async {
      final producto = await servicio.crearProducto(
        tienda,
        '  GAL-6 ',
        '  Galletas de coco x 6  ',
        UnidadMedida.unidad,
        null,
        Decimal.parse('3500'),
      );
      expect(producto.getCodigo(), 'GAL-6');
      expect(producto.getNombre(), 'Galletas de coco x 6');
    });

    test('acepta el precio de compra nulo (margen incompleto)', () async {
      final producto = await servicio.crearProducto(
        tienda,
        'ARR-1',
        'Arroz 1 lb',
        UnidadMedida.libra,
        null,
        Decimal.parse('2800'),
      );
      expect(producto.getPrecioCompra(), isNull);
    });

    test('acepta precios en cero', () async {
      final producto = await crearGalletas(precioCompra: Decimal.zero);
      expect(producto.getPrecioCompra(), Decimal.zero);
    });

    test('rechaza un código interno que ya existe en la tienda', () async {
      await crearGalletas();

      await expectLater(crearGalletas(), errorAlCrear());
      expect(await productos.listar(tienda), hasLength(1));
      expect(unidad.transacciones, 1);
    });

    test('el mismo código interno sí se puede usar en otra tienda', () async {
      await crearGalletas();

      final otro = await servicio.crearProducto(
        otraTienda,
        'GAL-6',
        'Galletas',
        UnidadMedida.unidad,
        null,
        Decimal.parse('3000'),
      );
      expect(await productos.listar(otraTienda), [otro]);
    });

    test('rechaza el código interno vacío', () async {
      await expectLater(crearGalletas(codigo: '   '), errorAlCrear());
      expect(unidad.transacciones, 0);
    });

    test('rechaza el nombre vacío', () async {
      await expectLater(
        servicio.crearProducto(
          tienda,
          'GAL-6',
          '  ',
          UnidadMedida.unidad,
          null,
          Decimal.parse('3500'),
        ),
        errorAlCrear(),
      );
      expect(unidad.transacciones, 0);
    });

    test('rechaza el precio de venta negativo', () async {
      await expectLater(
        servicio.crearProducto(
          tienda,
          'GAL-6',
          'Galletas',
          UnidadMedida.unidad,
          null,
          Decimal.parse('-1'),
        ),
        errorAlCrear(),
      );
      expect(await productos.listar(tienda), isEmpty);
    });

    test('rechaza el precio de compra negativo', () async {
      await expectLater(
        crearGalletas(precioCompra: Decimal.parse('-0.01')),
        errorAlCrear(),
      );
      expect(await productos.listar(tienda), isEmpty);
    });
  });

  group('editarProducto', () {
    late Producto producto;

    setUp(() async {
      producto = await crearGalletas();
      producto.setActualizadoEn(DateTime.utc(2026, 1, 1));
    });

    test('cambia los datos, asigna actualizadoEn y guarda', () async {
      final antes = DateTime.now().toUtc();

      await servicio.editarProducto(
        tienda,
        producto,
        '  Galletas de coco x 12 ',
        UnidadMedida.kilogramo,
        null,
        Decimal.parse('6800'),
      );

      expect(producto.getNombre(), 'Galletas de coco x 12');
      expect(producto.getUnidadMedida(), UnidadMedida.kilogramo);
      expect(producto.getPrecioCompra(), isNull);
      expect(producto.getPrecioVenta(), Decimal.parse('6800'));
      expect(producto.getActualizadoEn().isUtc, isTrue);
      expect(producto.getActualizadoEn().isBefore(antes), isFalse);
      expect(productos.guardadosEnTransaccion, hasLength(2));
      verificarPiezasPendientesSinUso();
    });

    test('no cambia el código interno', () async {
      await servicio.editarProducto(
        tienda,
        producto,
        'Otro nombre',
        UnidadMedida.unidad,
        null,
        Decimal.parse('100'),
      );
      expect(producto.getCodigo(), 'GAL-6');
    });

    test('no crea otro ítem de inventario', () async {
      await servicio.editarProducto(
        tienda,
        producto,
        'Otro nombre',
        UnidadMedida.unidad,
        null,
        Decimal.parse('100'),
      );
      expect(await items.listarItems(tienda), hasLength(1));
    });

    for (final (caso, nombre, compra, venta) in [
      ('nombre vacío', ' ', null, '3500'),
      ('precio de venta negativo', 'Galletas', null, '-5'),
      ('precio de compra negativo', 'Galletas', '-1', '3500'),
    ]) {
      test('rechaza $caso sin tocar el producto', () async {
        await expectLater(
          servicio.editarProducto(
            tienda,
            producto,
            nombre,
            UnidadMedida.libra,
            compra == null ? null : Decimal.parse(compra),
            Decimal.parse(venta),
          ),
          errorAlEditar(),
        );
        expect(producto.getNombre(), 'Galletas de coco x 6');
        expect(producto.getUnidadMedida(), UnidadMedida.unidad);
        expect(producto.getPrecioVenta(), Decimal.parse('3500'));
        expect(producto.getActualizadoEn(), DateTime.utc(2026, 1, 1));
        expect(productos.guardadosEnTransaccion, hasLength(1));
      });
    }
  });

  group('buscarPorNombre', () {
    test('delega en el repositorio y devuelve sus coincidencias', () async {
      final galletas = await crearGalletas();
      await servicio.crearProducto(
        tienda,
        'ARR-1',
        'Arroz Diana',
        UnidadMedida.libra,
        null,
        Decimal.parse('2800'),
      );

      final resultado = await servicio.buscarPorNombre(tienda, 'COCO');

      expect(resultado.map((p) => p.getId()), [galletas.getId()]);
      expect(productos.textosBuscados, ['COCO']);
      verificarPiezasPendientesSinUso();
    });

    test('solo busca en la tienda indicada', () async {
      await crearGalletas();

      expect(await servicio.buscarPorNombre(otraTienda, 'galletas'), isEmpty);
    });

    test('sin coincidencias devuelve una lista vacía', () async {
      await crearGalletas();

      expect(await servicio.buscarPorNombre(tienda, 'leche'), isEmpty);
    });
  });
}
