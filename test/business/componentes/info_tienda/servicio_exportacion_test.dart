import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/servicio_exportacion.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/formato_exportacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/transversal/errores/errores_exportacion.dart';

import '../gestion_inventario/fakes_catalogo.dart';
import '../pagos/fakes_pagos.dart';
import 'fakes_exportacion.dart';

/// exportar (CUS-16, RNF-22, DI-41).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final otraTienda = Tienda('t2', 'T002', 'Tienda Dos', 'Turbaco');
  Decimal d(String v) => Decimal.parse(v);

  final desde = DateTime.utc(2026, 10, 1);
  final hasta = DateTime.utc(2026, 11, 1);

  late InventarioRepositorioFalso inventario;
  late VentaRepositorioFalso ventas;
  late FiadoRepositorioFalso fiados;
  late ExportadorFalso exportador;
  late ServicioExportacion servicio;

  setUp(() {
    inventario = InventarioRepositorioFalso();
    ventas = VentaRepositorioFalso();
    fiados = FiadoRepositorioFalso();
    exportador = ExportadorFalso();
    servicio = ServicioExportacion(
      inventario,
      ventas,
      fiados,
      exportador,
      reloj: () => DateTime.utc(2026, 11, 2, 15),
    );
  });

  ItemInventario item(String id, String nombre) => ItemInventario(
    'i$id',
    Producto(id, 'C$id', nombre, UnidadMedida.unidad, d('100'), d('200')),
    d('10'),
  );

  Venta venta(String id, DateTime fecha) => Venta(
    id,
    [PagoContado('f$id', d('5000'), Decimal.zero)],
    d('5000'),
    fecha,
  );

  Fiado fiado(String id, DateTime fecha) =>
      Fiado(id, d('3000'), fecha, Cliente('c$id', 'Doña Rosa', ''));

  test('arma los datos con inventario, ventas del periodo y fiados', () async {
    await inventario.guardarItem(tienda, item('p1', 'Huevo AA'));
    await ventas.guardar(tienda, venta('v1', DateTime.utc(2026, 10, 15)));
    await fiados.crear(tienda, fiado('f1', DateTime.utc(2026, 9, 20)));

    final nombre = await servicio.exportar(
      tienda,
      desde,
      hasta,
      FormatoExportacion.excel,
    );

    expect(nombre, 'gip-prueba.xlsx');
    final datos = exportador.recibidos.single;
    expect(datos.getFormato(), FormatoExportacion.excel);
    expect(datos.getDesde(), desde);
    expect(datos.getHasta(), hasta);
    expect(datos.getFecha(), DateTime.utc(2026, 11, 2, 15));
    expect(datos.getItems().map((i) => i.getProducto().getNombre()), [
      'Huevo AA',
    ]);
    expect(datos.getVentas().map((v) => v.getId()), ['v1']);
    // Los fiados no se filtran por periodo: salen todos.
    expect(datos.getFiados().map((f) => f.getId()), ['f1']);
  });

  test('pasa el formato CSV al exportador', () async {
    await servicio.exportar(tienda, desde, hasta, FormatoExportacion.csv);

    expect(exportador.recibidos.single.getFormato(), FormatoExportacion.csv);
  });

  test('las ventas fuera del periodo no se exportan', () async {
    await ventas.guardar(tienda, venta('v1', DateTime.utc(2026, 9, 30, 23)));
    await ventas.guardar(tienda, venta('v2', DateTime.utc(2026, 10, 1)));
    await ventas.guardar(tienda, venta('v3', hasta));

    await servicio.exportar(tienda, desde, hasta, FormatoExportacion.csv);

    expect(exportador.recibidos.single.getVentas().map((v) => v.getId()), [
      'v2',
    ]);
  });

  test('solo exporta lo de la tienda pedida', () async {
    await inventario.guardarItem(tienda, item('p1', 'Mío'));
    await inventario.guardarItem(otraTienda, item('p2', 'Ajeno'));
    await ventas.guardar(tienda, venta('v1', DateTime.utc(2026, 10, 5)));
    await ventas.guardar(otraTienda, venta('v2', DateTime.utc(2026, 10, 5)));
    await fiados.crear(tienda, fiado('f1', DateTime.utc(2026, 10, 5)));
    await fiados.crear(otraTienda, fiado('f2', DateTime.utc(2026, 10, 5)));

    await servicio.exportar(tienda, desde, hasta, FormatoExportacion.csv);

    final datos = exportador.recibidos.single;
    expect(datos.getItems().map((i) => i.getProducto().getNombre()), ['Mío']);
    expect(datos.getVentas().map((v) => v.getId()), ['v1']);
    expect(datos.getFiados().map((f) => f.getId()), ['f1']);
  });

  test('una tienda sin datos exporta listas vacías', () async {
    await servicio.exportar(tienda, desde, hasta, FormatoExportacion.excel);

    final datos = exportador.recibidos.single;
    expect(datos.getItems(), isEmpty);
    expect(datos.getVentas(), isEmpty);
    expect(datos.getFiados(), isEmpty);
  });

  test('desde posterior a hasta: "Periodo no válido" y no exporta', () async {
    await ventas.guardar(tienda, venta('v1', DateTime.utc(2026, 10, 5)));

    await expectLater(
      servicio.exportar(tienda, hasta, desde, FormatoExportacion.excel),
      throwsA(
        isA<ExcepcionPeriodoNoValido>().having(
          (e) => e.mensaje,
          'mensaje',
          'Periodo no válido',
        ),
      ),
    );
    expect(exportador.recibidos, isEmpty);
  });

  test('desde igual a hasta es válido (periodo vacío)', () async {
    await servicio.exportar(tienda, desde, desde, FormatoExportacion.csv);

    expect(exportador.recibidos, hasLength(1));
    expect(exportador.recibidos.single.getVentas(), isEmpty);
  });

  test('si el exportador falla, el error llega a quien llamó', () async {
    exportador.fallar = true;

    await expectLater(
      servicio.exportar(tienda, desde, hasta, FormatoExportacion.excel),
      throwsA(isA<StateError>()),
    );
  });

  test('sin reloj propio usa la hora actual en UTC', () async {
    final real = ServicioExportacion(inventario, ventas, fiados, exportador);
    final antes = DateTime.now().toUtc();

    await real.exportar(tienda, desde, hasta, FormatoExportacion.csv);

    final fecha = exportador.recibidos.single.getFecha();
    expect(fecha.isUtc, isTrue);
    expect(fecha.isBefore(antes), isFalse);
  });
}
