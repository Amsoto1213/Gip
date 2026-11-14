import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_inventario/interprete_codigo.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_impresion_etiquetas.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_producto_repositorio.dart';
import 'package:gip/business/interfaces/i_unidad_trabajo.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';
import 'package:uuid/uuid.dart';

/// Pure Fabrication e Information Expert del catálogo: búsqueda por nombre o
/// por código y creación de productos (CUR-06, RF-06).
///
/// Por ahora tiene buscar por nombre (CUS-06), crear y editar (CUS-18). `interpretes` e `impresion` están
/// en el constructor de EA y los usarán "Asociar código" (CUS-17) y
/// "Etiquetas" (iteración 4); ningún flujo de CUS-18 los llama (DI-15).
class ServicioCatalogo {
  /// [interpretes] llega en orden: código de barras primero y QR de último.
  ServicioCatalogo(
    this._productos,
    this._interpretes,
    this._servicioInventario,
    this._impresion,
    this._unidadTrabajo,
  );

  final IProductoRepositorio _productos;
  final ServicioInventario _servicioInventario;
  final IUnidadTrabajo _unidadTrabajo;

  // Pendientes (DI-15): CUS-17 y la iteracion 4 de etiquetas.
  // ignore: unused_field
  final List<InterpreteCodigo> _interpretes;
  // ignore: unused_field
  final IImpresionEtiquetas _impresion;

  /// Delega en productos.buscarPorNombre; la coincidencia sin tildes ni
  /// mayúsculas la resuelve el repositorio (RD-08, CUS-06).
  Future<List<Producto>> buscarPorNombre(Tienda tienda, String texto) =>
      _productos.buscarPorNombre(tienda, texto);

  /// Creator: valida que el código no exista, el nombre no esté vacío y los
  /// precios no sean negativos ([precioCompra] puede ser nulo). Crea el
  /// producto con id nuevo y, en una sola transacción, lo guarda y crea su
  /// ítem con stock cero (RNF-04).
  Future<Producto> crearProducto(
    Tienda tienda,
    String codigo,
    String nombre,
    UnidadMedida unidad,
    Decimal? precioCompra,
    Decimal precioVenta,
  ) async {
    final codigoLimpio = codigo.trim();
    final nombreLimpio = nombre.trim();
    final existente = codigoLimpio.isEmpty
        ? null
        : await _productos.buscarPorCodigo(tienda, codigoLimpio);
    if (existente != null ||
        codigoLimpio.isEmpty ||
        !_datosValidos(nombreLimpio, precioCompra, precioVenta)) {
      throw const ExcepcionDatosProductoNoValidos.alCrear();
    }

    final producto = Producto(
      const Uuid().v4(),
      codigoLimpio,
      nombreLimpio,
      unidad,
      precioCompra,
      precioVenta,
    );
    await _unidadTrabajo.ejecutar(() async {
      await _productos.guardar(tienda, producto);
      await _servicioInventario.crearItem(tienda, producto);
    });
    return producto;
  }

  /// Valida igual que [crearProducto]; cambia los datos, asigna actualizadoEn y
  /// guarda. El código interno no se edita (DA-48, DA-50).
  Future<void> editarProducto(
    Tienda tienda,
    Producto producto,
    String nombre,
    UnidadMedida unidad,
    Decimal? precioCompra,
    Decimal precioVenta,
  ) async {
    final nombreLimpio = nombre.trim();
    if (!_datosValidos(nombreLimpio, precioCompra, precioVenta)) {
      throw const ExcepcionDatosProductoNoValidos.alEditar();
    }
    producto
      ..setNombre(nombreLimpio)
      ..setUnidadMedida(unidad)
      ..setPrecioCompra(precioCompra)
      ..setPrecioVenta(precioVenta)
      ..setActualizadoEn(DateTime.now().toUtc());
    await _productos.guardar(tienda, producto);
  }

  bool _datosValidos(
    String nombre,
    Decimal? precioCompra,
    Decimal precioVenta,
  ) =>
      nombre.isNotEmpty &&
      precioVenta >= Decimal.zero &&
      (precioCompra == null || precioCompra >= Decimal.zero);
}
