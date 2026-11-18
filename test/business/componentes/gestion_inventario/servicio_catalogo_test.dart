import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/interprete_codigo.dart';
import 'package:gip/business/componentes/gestion_inventario/interprete_codigo_barras.dart';
import 'package:gip/business/componentes/gestion_inventario/interprete_codigo_qr.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_catalogo.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
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

  setUpAll(() => registerFallbackValue(tienda));

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

  group('buscarPorLectura (CUS-17)', () {
    test('usa el primer intérprete que reconoce la lectura', () async {
      final segundo = InterpreteFalso();
      final tercero = InterpreteFalso();
      final galletas = await crearGalletas();
      when(() => interprete.reconoce(any())).thenReturn(false);
      when(() => segundo.reconoce(any())).thenReturn(true);
      when(() => segundo.buscar(tienda, 'ABC')).thenAnswer((_) async {
        return galletas;
      });
      final conTres = ServicioCatalogo(
        productos,
        [interprete, segundo, tercero],
        ServicioInventario(items, movimientos, Decimal.one, unidad, productos),
        impresion,
        unidad,
      );

      expect(await conTres.buscarPorLectura(tienda, 'ABC'), galletas);
      verify(() => interprete.reconoce('ABC')).called(1);
      verifyNever(() => interprete.buscar(any(), any()));
      verifyZeroInteractions(tercero);
    });

    test('quita los espacios del inicio y del final', () async {
      when(() => interprete.reconoce(any())).thenReturn(true);
      when(() => interprete.buscar(tienda, any()))
          .thenAnswer((_) async => null);

      await servicio.buscarPorLectura(tienda, '  7701234567897\n');

      verify(() => interprete.buscar(tienda, '7701234567897')).called(1);
    });

    test('una lectura vacía devuelve null sin buscar', () async {
      expect(await servicio.buscarPorLectura(tienda, '   '), isNull);
      verifyZeroInteractions(interprete);
    });

    test('si ningún intérprete la reconoce devuelve null', () async {
      when(() => interprete.reconoce(any())).thenReturn(false);

      expect(await servicio.buscarPorLectura(tienda, 'ABC'), isNull);
      verifyNever(() => interprete.buscar(any(), any()));
    });
  });

  group('con los intérpretes reales', () {
    late ServicioCatalogo real;
    late Producto galletas;

    setUp(() async {
      real = ServicioCatalogo(
        productos,
        [InterpreteCodigoBarras(productos), InterpreteCodigoQR(productos)],
        ServicioInventario(items, movimientos, Decimal.one, unidad, productos),
        impresion,
        unidad,
      );
      galletas = await crearGalletas();
    });

    group('asociarCodigo', () {
      test(
        'crea el código con id UUID v4, formato EAN-13 y lo guarda',
        () async {
          final codigo = await real.asociarCodigo(
            tienda,
            galletas,
            '7701234567897',
          );

          expect(codigo.getId(), matches(uuidV4));
          expect(codigo.getFormato(), FormatoCodigo.ean13);
          expect(codigo.getValor(), '7701234567897');
          expect(galletas.getCodigos(), [codigo]);
          expect(productos.guardadosEnTransaccion, hasLength(2));
          expect(
            await productos.buscarPorCodigoProducto(tienda, '7701234567897'),
            galletas,
          );
        },
      );

      test('deduce EAN-8, UPC-A y QR', () async {
        final ean8 = await real.asociarCodigo(tienda, galletas, '96385074');
        final upca = await real.asociarCodigo(tienda, galletas, '036000291452');
        final qr = await real.asociarCodigo(tienda, galletas, 'GIP:GAL-6');
        final errado = await real.asociarCodigo(
          tienda,
          galletas,
          '7701234567890',
        );

        expect(ean8.getFormato(), FormatoCodigo.ean8);
        expect(upca.getFormato(), FormatoCodigo.upca);
        expect(qr.getFormato(), FormatoCodigo.qr);
        expect(errado.getFormato(), FormatoCodigo.qr, reason: 'control errado');
        expect(galletas.getCodigos(), hasLength(4));
      });

      test('quita los espacios del inicio y del final', () async {
        final codigo = await real.asociarCodigo(
          tienda,
          galletas,
          ' 7701234567897 ',
        );
        expect(codigo.getValor(), '7701234567897');
      });

      test('rechaza el código vacío sin guardar', () async {
        await expectLater(
          real.asociarCodigo(tienda, galletas, '  '),
          throwsA(
            isA<ExcepcionCodigoVacio>().having(
              (e) => e.mensaje,
              'mensaje',
              'Escriba o lea el código',
            ),
          ),
        );
        expect(galletas.getCodigos(), isEmpty);
        expect(productos.guardadosEnTransaccion, hasLength(1));
      });

      test('rechaza un código que ya es de otro producto (paso 25)', () async {
        final arroz = await servicio.crearProducto(
          tienda,
          'ARR-1',
          'Arroz Diana',
          UnidadMedida.libra,
          null,
          Decimal.parse('2800'),
        );
        await real.asociarCodigo(tienda, arroz, '7701234567897');

        await expectLater(
          real.asociarCodigo(tienda, galletas, '7701234567897'),
          throwsA(
            isA<ExcepcionCodigoRepetido>().having(
              (e) => e.mensaje,
              'mensaje',
              'Ese código ya está asociado a otro producto',
            ),
          ),
        );
        expect(galletas.getCodigos(), isEmpty);
      });

      test('el mismo código sí se puede usar en otra tienda', () async {
        await real.asociarCodigo(tienda, galletas, '7701234567897');
        final otro = await servicio.crearProducto(
          otraTienda,
          'GAL-6',
          'Galletas',
          UnidadMedida.unidad,
          null,
          Decimal.parse('3000'),
        );

        final codigo = await real.asociarCodigo(
          otraTienda,
          otro,
          '7701234567897',
        );
        expect(otro.getCodigos(), [codigo]);
      });

      test(
        'si ya es de este producto, devuelve el mismo sin repetir',
        () async {
          final primero = await real.asociarCodigo(
            tienda,
            galletas,
            '7701234567897',
          );

          final segundo = await real.asociarCodigo(
            tienda,
            galletas,
            '7701234567897',
          );

          expect(segundo, same(primero));
          expect(galletas.getCodigos(), [primero]);
          expect(productos.guardadosEnTransaccion, hasLength(2));
        },
      );

      test('si el guardado falla, el código no queda en el producto', () async {
        productos.fallar = true;

        await expectLater(
          real.asociarCodigo(tienda, galletas, '7701234567897'),
          throwsStateError,
        );
        expect(galletas.getCodigos(), isEmpty);
      });
    });

    group('buscarPorLectura', () {
      test('encuentra el producto por su código de barras', () async {
        await real.asociarCodigo(tienda, galletas, '7701234567897');

        expect(await real.buscarPorLectura(tienda, '7701234567897'), galletas);
      });

      test('encuentra el producto por su QR con el texto exacto', () async {
        await real.asociarCodigo(tienda, galletas, 'GIP:GAL-6');

        expect(await real.buscarPorLectura(tienda, 'GIP:GAL-6'), galletas);
        expect(await real.buscarPorLectura(tienda, 'gip:gal-6'), isNull);
        expect(await real.buscarPorLectura(tienda, 'GAL-6'), isNull);
      });

      test('no compara con el código interno (DA-41)', () async {
        expect(await real.buscarPorLectura(tienda, 'GAL-6'), isNull);
      });

      test('un código no registrado devuelve null', () async {
        expect(await real.buscarPorLectura(tienda, '4006381333931'), isNull);
      });

      test('solo busca en la tienda indicada', () async {
        await real.asociarCodigo(tienda, galletas, '7701234567897');

        expect(
          await real.buscarPorLectura(otraTienda, '7701234567897'),
          isNull,
        );
      });
    });
  });
}
