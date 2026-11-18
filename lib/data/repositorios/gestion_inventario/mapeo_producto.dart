import 'package:drift/drift.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/transversal/texto/normalizar_texto.dart';
import 'package:gip/data/local/base_local_drift.dart';

/// Conversión entre las filas de `productos` y `codigos_producto` y las
/// entidades [Producto] y [CodigoProducto].
/// La unidad se guarda en mayúsculas (UNIDAD, KILOGRAMO, LIBRA), igual que el
/// enum `unidad_medida` de Supabase.
abstract final class MapeoProducto {
  static String unidadASql(UnidadMedida unidad) => unidad.name.toUpperCase();

  static UnidadMedida unidadDeSql(String valor) =>
      UnidadMedida.values.byName(valor.toLowerCase());

  /// El formato se guarda en mayúsculas (EAN13, EAN8, UPCA, QR).
  static String formatoASql(FormatoCodigo formato) =>
      formato.name.toUpperCase();

  static FormatoCodigo formatoDeSql(String valor) =>
      FormatoCodigo.values.byName(valor.toLowerCase());

  /// [codigos] son las filas de `codigos_producto` del producto. Solo
  /// `ProductoRepositorioDrift` las lee; los demás repositorios arman el
  /// producto sin códigos porque no los usan.
  static Producto aEntidad(
    FilaProducto fila, {
    List<FilaCodigoProducto> codigos = const [],
  }) {
    final producto = Producto(
      fila.id,
      fila.codigo,
      fila.nombre,
      unidadDeSql(fila.unidadMedida),
      fila.precioCompra,
      fila.precioVenta,
    )..setActualizadoEn(fila.actualizadoEn);
    for (final c in codigos) {
      producto.agregarCodigo(codigoAEntidad(c));
    }
    return producto;
  }

  static CodigoProducto codigoAEntidad(FilaCodigoProducto fila) =>
      CodigoProducto(fila.id, formatoDeSql(fila.formato), fila.valor);

  static CodigosProductoCompanion codigoAFila(
    Tienda tienda,
    Producto producto,
    CodigoProducto codigo,
  ) => CodigosProductoCompanion.insert(
    id: codigo.getId(),
    tiendaId: tienda.getId(),
    productoId: producto.getId(),
    formato: formatoASql(codigo.getFormato()),
    valor: codigo.getValor(),
    creadoEn: DateTime.now().toUtc(),
  );

  static ProductosCompanion aFila(Tienda tienda, Producto producto) =>
      ProductosCompanion.insert(
        id: producto.getId(),
        tiendaId: tienda.getId(),
        codigo: producto.getCodigo(),
        nombre: producto.getNombre(),
        nombreNormalizado: normalizarTexto(producto.getNombre()),
        unidadMedida: unidadASql(producto.getUnidadMedida()),
        precioCompra: Value(producto.getPrecioCompra()),
        precioVenta: producto.getPrecioVenta(),
        actualizadoEn: producto.getActualizadoEn(),
      );
}
