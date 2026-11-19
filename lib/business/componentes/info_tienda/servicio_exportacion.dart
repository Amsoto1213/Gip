import 'package:gip/business/entidades/info_tienda/datos_exportacion.dart';
import 'package:gip/business/entidades/info_tienda/formato_exportacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_inventario_repositorio.dart';
import 'package:gip/business/interfaces/info_tienda/i_exportador.dart';
import 'package:gip/business/interfaces/pagos/i_fiado_repositorio.dart';
import 'package:gip/business/interfaces/pagos/i_venta_repositorio.dart';
import 'package:gip/transversal/errores/errores_exportacion.dart';

/// Pure Fabrication y Creator de la exportación (CUS-16, RNF-22): reúne los
/// datos del negocio y se los entrega a [IExportador] (DA-68).
class ServicioExportacion {
  /// [reloj] da la fecha y hora de la exportación; por defecto, la actual.
  ServicioExportacion(
    this._items,
    this._ventas,
    this._fiados,
    this._exportador, {
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  final IInventarioRepositorio _items;
  final IVentaRepositorio _ventas;
  final IFiadoRepositorio _fiados;
  final IExportador _exportador;
  final DateTime Function() _reloj;

  /// Valida `desde <= hasta`; crea [DatosExportacion] con
  /// `items.listarItems(tienda)`, `ventas.listarPorPeriodo(tienda, desde,
  /// hasta)` y `fiados.listar(tienda)`, y llama a `exportador.exportar(datos)`.
  /// Devuelve el nombre del archivo (RNF-22).
  ///
  /// El periodo es `[desde, hasta)`, como en DI-28; los fiados salen todos,
  /// pendientes y saldados, porque su saldo no depende del periodo (DI-41).
  /// Si `desde` es posterior a `hasta` lanza [ExcepcionPeriodoNoValido] sin leer
  /// nada.
  Future<String> exportar(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
    FormatoExportacion formato,
  ) async {
    if (desde.isAfter(hasta)) throw const ExcepcionPeriodoNoValido();

    final items = await _items.listarItems(tienda);
    final ventas = await _ventas.listarPorPeriodo(tienda, desde, hasta);
    final fiados = await _fiados.listar(tienda);
    final datos = DatosExportacion(
      _reloj().toUtc(),
      desde,
      hasta,
      formato,
      items,
      ventas,
      fiados,
    );
    return _exportador.exportar(datos);
  }
}
