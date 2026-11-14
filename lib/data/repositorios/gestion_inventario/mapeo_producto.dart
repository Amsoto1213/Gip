import 'package:drift/drift.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/data/helpers/normalizar_texto.dart';
import 'package:gip/data/local/base_local_drift.dart';

/// Conversión entre la fila de `productos` y la entidad [Producto].
/// La unidad se guarda en mayúsculas (UNIDAD, KILOGRAMO, LIBRA), igual que el
/// enum `unidad_medida` de Supabase.
abstract final class MapeoProducto {
  static String unidadASql(UnidadMedida unidad) => unidad.name.toUpperCase();

  static UnidadMedida unidadDeSql(String valor) =>
      UnidadMedida.values.byName(valor.toLowerCase());

  /// Sin códigos de barras ni QR: la tabla `codigos_producto` llega con
  /// "Asociar código" (CUS-17).
  static Producto aEntidad(FilaProducto fila) => Producto(
    fila.id,
    fila.codigo,
    fila.nombre,
    unidadDeSql(fila.unidadMedida),
    fila.precioCompra,
    fila.precioVenta,
  )..setActualizadoEn(fila.actualizadoEn);

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
