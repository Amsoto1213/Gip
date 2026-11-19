import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:decimal/decimal.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/datos_exportacion.dart';
import 'package:gip/business/entidades/info_tienda/formato_exportacion.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/anulacion_venta.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/data/helpers/exportador_csv_excel.dart';

/// ExportadorCsvExcel (CUS-16, RNF-22, DI-41): el contenido de los archivos.
void main() {
  Decimal d(String v) => Decimal.parse(v);

  // Fechas locales: el archivo las muestra en hora local, así la prueba no
  // depende de la zona horaria de quien la corre.
  final desde = DateTime(2026, 10, 1);
  final hasta = DateTime(2026, 11, 1);
  final ahora = DateTime(2026, 11, 2, 15).toUtc();

  late List<ArchivoExportado> entregados;
  late ExportadorCsvExcel exportador;

  setUp(() {
    entregados = [];
    exportador = ExportadorCsvExcel(
      entregar: (archivos) async => entregados = archivos,
    );
  });

  DatosExportacion datos(
    FormatoExportacion formato, {
    List<ItemInventario>? items,
    List<Venta>? ventas,
    List<Fiado>? fiados,
    DateTime? d1,
    DateTime? d2,
  }) => DatosExportacion(
    ahora,
    d1 ?? desde,
    d2 ?? hasta,
    formato,
    items ?? [_huevo(), _cafe()],
    ventas ?? _ventas(),
    fiados ?? _fiados(),
  );

  /// Valores de una hoja como texto: los números sin ceros de más.
  List<List<String>> hoja(Excel libro, String nombre) => [
    for (final fila in libro.tables[nombre]!.rows)
      [
        for (final celda in fila)
          switch (celda?.value) {
            null => '',
            DoubleCellValue(:final value) =>
              value == value.roundToDouble() ? '${value.toInt()}' : '$value',
            final otro => '$otro',
          },
      ],
  ];

  List<List<String>> filasCsv(ArchivoExportado archivo) {
    final texto = utf8.decode(archivo.bytes.sublist(3));
    return [
      for (final fila in Csv().decode(texto))
        [for (final celda in fila) '$celda'],
    ];
  }

  group('Excel', () {
    test('un solo libro con tres hojas y el nombre del periodo', () async {
      final nombre = await exportador.exportar(datos(FormatoExportacion.excel));

      expect(nombre, 'gip-2026-10-01_a_2026-10-31.xlsx');
      expect(entregados, hasLength(1));
      expect(entregados.single.nombre, nombre);
      expect(entregados.single.tipoMime, ExportadorCsvExcel.tipoExcel);
      final libro = Excel.decodeBytes(entregados.single.bytes);
      expect(libro.tables.keys, ['Inventario', 'Ventas', 'Fiados']);
    });

    test('Inventario: producto, unidad, existencia y precios', () async {
      await exportador.exportar(datos(FormatoExportacion.excel));

      final filas = hoja(
        Excel.decodeBytes(entregados.single.bytes),
        ExportadorCsvExcel.hojaInventario,
      );

      expect(filas, [
        [
          'Código',
          'Producto',
          'Unidad',
          'Existencia',
          'Precio de compra',
          'Precio de venta',
        ],
        ['H1', 'Huevo AA', 'Unidad', '120', '400', '550'],
        // Café: sin precio de compra y por libras, con decimales.
        ['C1', 'Café', 'Libra', '2.5', '', '8900'],
      ]);
    });

    test('las cantidades y el dinero son números, no texto', () async {
      await exportador.exportar(datos(FormatoExportacion.excel));

      final libro = Excel.decodeBytes(entregados.single.bytes);
      final fila = libro.tables['Inventario']!.rows[1];
      // Al releer, Excel da IntCellValue a los enteros (120) y DoubleCellValue
      // a los decimales: los dos son números.
      final numero = anyOf(isA<IntCellValue>(), isA<DoubleCellValue>());
      expect(fila[3]?.value, numero);
      expect(fila[5]?.value, numero);
      expect(libro.tables['Inventario']!.rows[2][3]?.value, numero);
      expect(fila[1]?.value, isA<TextCellValue>());
    });

    test(
      'Ventas: total y formas de pago, y la anulación con su motivo',
      () async {
        await exportador.exportar(datos(FormatoExportacion.excel));

        final filas = hoja(
          Excel.decodeBytes(entregados.single.bytes),
          ExportadorCsvExcel.hojaVentas,
        );

        expect(filas.first, [
          'Fecha',
          'Total',
          'Efectivo',
          'Nequi',
          'Fiado',
          'Estado',
          'Anulada el',
          'Motivo de la anulación',
          'Anulada por',
        ]);
        expect(filas, hasLength(4));
        // Contado: 10000 recibidos - 4000 de cambio = 6000 en caja.
        expect(filas[1], [
          '2026-10-05 09:30',
          '6000',
          '6000',
          '0',
          '0',
          'Vigente',
          '',
          '',
          '',
        ]);
        // Contado + Nequi + fiado en una sola venta.
        expect(filas[2], [
          '2026-10-06 18:05',
          '20000',
          '5000',
          '7000',
          '8000',
          'Vigente',
          '',
          '',
          '',
        ]);
        expect(filas[3], [
          '2026-10-07 11:00',
          '3000',
          '3000',
          '0',
          '0',
          'Anulada',
          '2026-10-07 11:20',
          'Se equivocó de producto',
          'Carmen Ruiz',
        ]);
      },
    );

    test('Fiados: abonos vigentes, total abonado y saldo; el anulado no '
        'cuenta', () async {
      await exportador.exportar(datos(FormatoExportacion.excel));

      final filas = hoja(
        Excel.decodeBytes(entregados.single.bytes),
        ExportadorCsvExcel.hojaFiados,
      );

      expect(filas.first, [
        'Cliente',
        'Teléfono',
        'Fecha',
        'Monto inicial',
        'Abonos',
        'Total abonado',
        'Saldo pendiente',
        'Estado',
      ]);
      expect(filas[1], [
        'María Pérez',
        '300 412 4521',
        '2026-09-20 10:00',
        '20000',
        '2',
        '5000',
        '15000',
        'Pendiente',
      ]);
      expect(filas[2], [
        'Cliente eliminado',
        '',
        '2026-10-02 08:00',
        '3000',
        '0',
        '0',
        '0',
        'Anulado',
      ]);
    });

    test(
      'sin datos: las tres hojas existen solo con sus encabezados',
      () async {
        await exportador.exportar(
          datos(
            FormatoExportacion.excel,
            items: const [],
            ventas: const [],
            fiados: const [],
          ),
        );

        final libro = Excel.decodeBytes(entregados.single.bytes);
        for (final nombre in ['Inventario', 'Ventas', 'Fiados']) {
          expect(hoja(libro, nombre), hasLength(1), reason: nombre);
        }
      },
    );
  });

  group('CSV', () {
    test(
      'tres archivos con el mismo nombre base; devuelve el nombre base',
      () async {
        final nombre = await exportador.exportar(datos(FormatoExportacion.csv));

        expect(nombre, 'gip-2026-10-01_a_2026-10-31');
        expect(entregados.map((a) => a.nombre), [
          'gip-2026-10-01_a_2026-10-31-inventario.csv',
          'gip-2026-10-01_a_2026-10-31-ventas.csv',
          'gip-2026-10-01_a_2026-10-31-fiados.csv',
        ]);
        expect(
          entregados.map((a) => a.tipoMime),
          everyElement(ExportadorCsvExcel.tipoCsv),
        );
      },
    );

    test('empiezan con BOM UTF-8 para que Excel respete las tildes', () async {
      await exportador.exportar(datos(FormatoExportacion.csv));

      for (final archivo in entregados) {
        expect(archivo.bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      }
      expect(utf8.decode(entregados[0].bytes.sublist(3)), contains('Código'));
    });

    test('inventario: mismas columnas y valores que la hoja', () async {
      await exportador.exportar(datos(FormatoExportacion.csv));

      expect(filasCsv(entregados[0]), [
        [
          'Código',
          'Producto',
          'Unidad',
          'Existencia',
          'Precio de compra',
          'Precio de venta',
        ],
        ['H1', 'Huevo AA', 'Unidad', '120', '400', '550'],
        ['C1', 'Café', 'Libra', '2.5', '', '8900'],
      ]);
    });

    test('ventas y fiados: una fila por registro', () async {
      await exportador.exportar(datos(FormatoExportacion.csv));

      expect(filasCsv(entregados[1]), hasLength(4));
      expect(filasCsv(entregados[1])[2][1], '20000');
      expect(filasCsv(entregados[1])[3][7], 'Se equivocó de producto');
      expect(filasCsv(entregados[2]), hasLength(3));
      expect(filasCsv(entregados[2])[1][0], 'María Pérez');
    });

    test('un nombre con coma, comillas o salto de línea no rompe las '
        'columnas', () async {
      final raro = ItemInventario(
        'i9',
        Producto(
          'p9',
          'R1',
          'Sal, "fina"\nx 500 g',
          UnidadMedida.unidad,
          d('1'),
          d('2'),
        ),
        d('3'),
      );

      await exportador.exportar(datos(FormatoExportacion.csv, items: [raro]));

      final filas = filasCsv(entregados[0]);
      expect(filas, hasLength(2));
      expect(filas[1], ['R1', 'Sal, "fina"\nx 500 g', 'Unidad', '3', '1', '2']);
    });

    test('sin datos: tres archivos solo con encabezados', () async {
      await exportador.exportar(
        datos(
          FormatoExportacion.csv,
          items: const [],
          ventas: const [],
          fiados: const [],
        ),
      );

      expect(entregados, hasLength(3));
      for (final archivo in entregados) {
        expect(filasCsv(archivo), hasLength(1));
      }
    });
  });

  group('nombre del archivo', () {
    test('el último día es el anterior a hasta (hasta no se incluye)', () {
      expect(
        ExportadorCsvExcel.nombreBase(
          datos(
            FormatoExportacion.csv,
            d1: DateTime(2026, 11, 10),
            d2: DateTime(2026, 11, 11),
          ),
        ),
        'gip-2026-11-10_a_2026-11-10',
      );
    });

    test('un periodo vacío (desde = hasta) usa solo el día de desde', () {
      expect(
        ExportadorCsvExcel.nombreBase(
          datos(
            FormatoExportacion.csv,
            d1: DateTime(2026, 11, 10),
            d2: DateTime(2026, 11, 10),
          ),
        ),
        'gip-2026-11-10_a_2026-11-10',
      );
    });

    test('el periodo cruza el fin de año', () {
      expect(
        ExportadorCsvExcel.nombreBase(
          datos(
            FormatoExportacion.csv,
            d1: DateTime(2026, 12, 15),
            d2: DateTime(2027, 1, 1),
          ),
        ),
        'gip-2026-12-15_a_2026-12-31',
      );
    });
  });

  test('si la entrega falla, el error llega a quien llamó', () async {
    final falla = ExportadorCsvExcel(
      entregar: (_) async => throw StateError('sin espacio'),
    );

    await expectLater(
      falla.exportar(datos(FormatoExportacion.excel)),
      throwsA(isA<StateError>()),
    );
  });
}

ItemInventario _huevo() => ItemInventario(
  'i1',
  Producto(
    'p1',
    'H1',
    'Huevo AA',
    UnidadMedida.unidad,
    Decimal.parse('400'),
    Decimal.parse('550'),
  ),
  Decimal.parse('120'),
);

ItemInventario _cafe() => ItemInventario(
  'i2',
  Producto('p2', 'C1', 'Café', UnidadMedida.libra, null, Decimal.parse('8900')),
  Decimal.parse('2.5'),
);

List<Venta> _ventas() {
  Decimal d(String v) => Decimal.parse(v);
  final maria = Cliente('c1', 'María Pérez', '300 412 4521');
  final fiado = Fiado('fv2', d('8000'), DateTime(2026, 10, 6, 18, 5), maria);
  final anulada = Venta(
    'v3',
    [PagoContado('p3', d('3000'), Decimal.zero)],
    d('3000'),
    DateTime(2026, 10, 7, 11),
    anulacion: AnulacionVenta(
      'an1',
      Administrador('u1', 'Carmen Ruiz', '1000000001'),
      DateTime(2026, 10, 7, 11, 20).toUtc(),
      'Se equivocó de producto',
    ),
  );
  return [
    Venta(
      'v1',
      [PagoContado('p1', d('10000'), d('4000'))],
      d('6000'),
      DateTime(2026, 10, 5, 9, 30),
    ),
    Venta(
      'v2',
      [
        PagoContado('p2', d('5000'), Decimal.zero),
        PagoNequi('n2', d('7000'), null),
        fiado,
      ],
      d('20000'),
      DateTime(2026, 10, 6, 18, 5),
    ),
    anulada,
  ];
}

List<Fiado> _fiados() {
  Decimal d(String v) => Decimal.parse(v);
  final maria = Cliente('c1', 'María Pérez', '300 412 4521');
  final eliminado = Cliente('c2', 'Cliente eliminado', '');
  return [
    Fiado.guardado(
      'f1',
      d('20000'),
      DateTime(2026, 9, 20, 10),
      maria,
      d('15000'),
      EstadoFiado.pendiente,
      [
        Abono('a1', d('2000'), DateTime(2026, 9, 25), MedioPago.efectivo, null),
        Abono('a2', d('3000'), DateTime(2026, 10, 3), MedioPago.nequi, null),
        // Un abono anulado no cuenta ni en el número ni en el total.
        Abono(
          'a3',
          d('9999'),
          DateTime(2026, 10, 4),
          MedioPago.efectivo,
          null,
          anulado: true,
        ),
      ],
    ),
    Fiado.guardado(
      'f2',
      d('3000'),
      DateTime(2026, 10, 2, 8),
      eliminado,
      Decimal.zero,
      EstadoFiado.anulado,
    ),
  ];
}
