import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:decimal/decimal.dart';
import 'package:excel/excel.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/datos_exportacion.dart';
import 'package:gip/business/entidades/info_tienda/formato_exportacion.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/info_tienda/i_exportador.dart';
import 'package:share_plus/share_plus.dart';

/// Un archivo ya armado, listo para entregar.
typedef ArchivoExportado = ({String nombre, Uint8List bytes, String tipoMime});

/// Protected Variations: arma el archivo de la exportación (CUS-16, RNF-22,
/// DA-68, DI-41).
///
/// - **Excel:** un libro `.xlsx` con tres hojas: Inventario, Ventas y Fiados.
///   El dinero y las cantidades van como números, para poder sumarlos.
/// - **CSV:** tres archivos (inventario, ventas y fiados), con coma, UTF-8 con
///   BOM para que Excel respete las tildes, y los números con punto decimal.
///
/// Las fechas van en hora local, `AAAA-MM-DD HH:mm`. Cada archivo se entrega
/// con el menú de compartir del sistema; en la web, si el navegador no puede
/// compartir, se descarga (`share_plus`). `exportar` devuelve el nombre del
/// archivo y, en CSV, el nombre base común de los tres (DI-41).
class ExportadorCsvExcel implements IExportador {
  /// [entregar] recibe los archivos ya armados; por defecto abre el menú de
  /// compartir o descarga de `share_plus`.
  ExportadorCsvExcel({
    Future<void> Function(List<ArchivoExportado> archivos)? entregar,
  }) : _entregar = entregar ?? _compartir;

  final Future<void> Function(List<ArchivoExportado> archivos) _entregar;

  static const hojaInventario = 'Inventario';
  static const hojaVentas = 'Ventas';
  static const hojaFiados = 'Fiados';

  static const tipoExcel =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const tipoCsv = 'text/csv';

  static Future<void> _compartir(List<ArchivoExportado> archivos) =>
      SharePlus.instance.share(
        ShareParams(
          files: [
            for (final a in archivos)
              XFile.fromData(a.bytes, mimeType: a.tipoMime, name: a.nombre),
          ],
          fileNameOverrides: [for (final a in archivos) a.nombre],
        ),
      );

  @override
  Future<String> exportar(DatosExportacion datos) async {
    final archivos = armarArchivos(datos);
    await _entregar(archivos);
    return datos.getFormato() == FormatoExportacion.excel
        ? archivos.single.nombre
        : nombreBase(datos);
  }

  /// `gip-AAAA-MM-DD_a_AAAA-MM-DD`, con el primer y el último día del periodo
  /// (el `hasta` de los datos no se incluye). No lleva el nombre de la tienda
  /// porque `DatosExportacion` no lo tiene (DI-41).
  static String nombreBase(DatosExportacion datos) {
    final primero = datos.getDesde().toLocal();
    final tope = datos.getHasta().toLocal();
    final ultimo = tope.isAfter(primero)
        ? DateTime(tope.year, tope.month, tope.day - 1)
        : primero;
    return 'gip-${_dia(primero)}_a_${_dia(ultimo)}';
  }

  /// Arma los archivos según `datos.getFormato()`: uno en Excel, tres en CSV.
  List<ArchivoExportado> armarArchivos(DatosExportacion datos) {
    final tablas = _tablas(datos);
    final base = nombreBase(datos);
    if (datos.getFormato() == FormatoExportacion.excel) {
      return [
        (
          nombre: '$base.xlsx',
          bytes: Uint8List.fromList(_libro(tablas)),
          tipoMime: tipoExcel,
        ),
      ];
    }
    return [
      for (final e in tablas.entries)
        (
          nombre: '$base-${e.key.toLowerCase()}.csv',
          bytes: Uint8List.fromList(_csv(e.value)),
          tipoMime: tipoCsv,
        ),
    ];
  }

  /// Encabezados y filas de cada hoja. Los valores son [String], [Decimal],
  /// [int] o null (celda vacía).
  Map<String, List<List<Object?>>> _tablas(DatosExportacion datos) => {
    hojaInventario: [
      [
        'Código',
        'Producto',
        'Unidad',
        'Existencia',
        'Precio de compra',
        'Precio de venta',
      ],
      for (final item in datos.getItems())
        [
          item.getProducto().getCodigo(),
          item.getProducto().getNombre(),
          _unidad(item.getProducto().getUnidadMedida()),
          item.getStockActual(),
          item.getProducto().getPrecioCompra(),
          item.getProducto().getPrecioVenta(),
        ],
    ],
    hojaVentas: [
      [
        'Fecha',
        'Total',
        'Efectivo',
        'Nequi',
        'Fiado',
        'Estado',
        'Anulada el',
        'Motivo de la anulación',
        'Anulada por',
      ],
      for (final venta in datos.getVentas()) _filaVenta(venta),
    ],
    hojaFiados: [
      [
        'Cliente',
        'Teléfono',
        'Fecha',
        'Monto inicial',
        'Abonos',
        'Total abonado',
        'Saldo pendiente',
        'Estado',
      ],
      for (final fiado in datos.getFiados()) _filaFiado(fiado),
    ],
  };

  List<Object?> _filaVenta(Venta venta) {
    var efectivo = Decimal.zero;
    var nequi = Decimal.zero;
    var fiado = Decimal.zero;
    for (final forma in venta.getFormasPago()) {
      if (forma is PagoContado) efectivo += forma.calcularMontoCubierto();
      if (forma is PagoNequi) nequi += forma.calcularMontoCubierto();
      if (forma is Fiado) fiado += forma.calcularMontoCubierto();
    }
    final anulacion = venta.getAnulacion();
    return [
      _fechaHora(venta.getFecha()),
      venta.getTotal(),
      efectivo,
      nequi,
      fiado,
      anulacion == null ? 'Vigente' : 'Anulada',
      anulacion == null ? null : _fechaHora(anulacion.getFecha()),
      anulacion?.getMotivo(),
      anulacion?.getUsuarioNombre(),
    ];
  }

  List<Object?> _filaFiado(Fiado fiado) {
    // Los abonos anulados no cuentan: no bajan el saldo (CUS-20).
    final vigentes = fiado.getAbonos().where((a) => !a.isAnulado()).toList();
    return [
      fiado.getCliente().getNombre(),
      fiado.getCliente().getTelefono(),
      _fechaHora(fiado.getFechaInicio()),
      fiado.getMontoInicial(),
      vigentes.length,
      vigentes.fold<Decimal>(Decimal.zero, (suma, a) => suma + a.getMonto()),
      fiado.getSaldoPendiente(),
      switch (fiado.getEstado()) {
        EstadoFiado.pendiente => 'Pendiente',
        EstadoFiado.saldado => 'Saldado',
        EstadoFiado.anulado => 'Anulado',
      },
    ];
  }

  List<int> _libro(Map<String, List<List<Object?>>> tablas) {
    final libro = Excel.createExcel();
    final porDefecto = libro.getDefaultSheet();
    for (final e in tablas.entries) {
      final hoja = libro[e.key];
      for (final fila in e.value) {
        hoja.appendRow([for (final celda in fila) _celda(celda)]);
      }
    }
    if (porDefecto != null && !tablas.containsKey(porDefecto)) {
      libro.delete(porDefecto);
    }
    return libro.encode() ?? const [];
  }

  static CellValue? _celda(Object? valor) => switch (valor) {
    null => null,
    Decimal() => DoubleCellValue(valor.toDouble()),
    int() => IntCellValue(valor),
    _ => TextCellValue('$valor'),
  };

  List<int> _csv(List<List<Object?>> filas) {
    final texto = Csv().encode([
      for (final fila in filas)
        [for (final celda in fila) celda?.toString() ?? ''],
    ]);
    // BOM propio: así Excel abre el UTF-8 con sus tildes.
    return [0xEF, 0xBB, 0xBF, ...utf8.encode(texto)];
  }

  static String _unidad(UnidadMedida unidad) => switch (unidad) {
    UnidadMedida.unidad => 'Unidad',
    UnidadMedida.kilogramo => 'Kilogramo',
    UnidadMedida.libra => 'Libra',
  };

  static String _dia(DateTime f) => '${f.year}-${_dos(f.month)}-${_dos(f.day)}';

  static String _fechaHora(DateTime fecha) {
    final f = fecha.toLocal();
    return '${_dia(f)} ${_dos(f.hour)}:${_dos(f.minute)}';
  }

  static String _dos(int n) => n.toString().padLeft(2, '0');
}
