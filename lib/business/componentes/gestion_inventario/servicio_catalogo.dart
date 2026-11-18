import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_inventario/interprete_codigo.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/codigo_producto.dart';
import 'package:gip/business/entidades/gestion_inventario/etiqueta.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_impresion_etiquetas.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_producto_repositorio.dart';
import 'package:gip/business/interfaces/i_unidad_trabajo.dart';
import 'package:gip/transversal/configuracion/configuracion_inventario.dart';
import 'package:gip/transversal/errores/errores_inventario.dart';
import 'package:uuid/uuid.dart';

/// Pure Fabrication e Information Expert del catálogo: búsqueda por nombre o
/// por código y creación de productos (CUR-06, RF-06).
///
/// Tiene buscar por nombre (CUS-06), por lectura (CUS-17), crear, editar y
/// asociar código e imprimir etiquetas (CUS-18).
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

  final List<InterpreteCodigo> _interpretes;
  final IImpresionEtiquetas _impresion;

  /// Delega en productos.buscarPorNombre; la coincidencia sin tildes ni
  /// mayúsculas la resuelve el repositorio (RD-08, CUS-06).
  Future<List<Producto>> buscarPorNombre(Tienda tienda, String texto) =>
      _productos.buscarPorNombre(tienda, texto);

  /// Recorre los intérpretes en orden; el primero que reconoce la lectura la
  /// busca y se devuelve su resultado, o null si no hay producto
  /// (Polymorphism, RF-06, CUS-17). Se quitan los espacios del inicio y del
  /// final; una lectura vacía devuelve null sin buscar (DI-34).
  Future<Producto?> buscarPorLectura(Tienda tienda, String lectura) async {
    final texto = lectura.trim();
    if (texto.isEmpty) return null;
    final interprete = _primeroQueReconoce(texto);
    return interprete?.buscar(tienda, texto);
  }

  /// Asocia un código de barras o QR al producto (CUS-18, pasos 18 a 33).
  /// Rechaza con [ExcepcionCodigoRepetido] si el código ya es de otro producto
  /// de la tienda (DA-41). El formato lo deduce el primer intérprete que
  /// reconoce el valor (DA-47).
  ///
  /// Casos que el diagrama no cubre (DI-34): se quitan los espacios del inicio
  /// y del final; un valor vacío se rechaza con [ExcepcionCodigoVacio]; si el
  /// código ya es de este mismo producto se devuelve ese código sin repetirlo;
  /// si el guardado falla, el código se quita del producto antes de relanzar.
  Future<CodigoProducto> asociarCodigo(
    Tienda tienda,
    Producto producto,
    String valor,
  ) async {
    final texto = valor.trim();
    if (texto.isEmpty) throw const ExcepcionCodigoVacio();

    final otro = await _productos.buscarPorCodigoProducto(tienda, texto);
    if (otro != null && otro.getId() != producto.getId()) {
      throw const ExcepcionCodigoRepetido();
    }
    final yaAsociado = [
      ...producto.getCodigos(),
      ...?otro?.getCodigos(),
    ].where((c) => c.getValor() == texto).firstOrNull;
    if (yaAsociado != null) {
      if (!producto.getCodigos().contains(yaAsociado)) {
        producto.agregarCodigo(yaAsociado);
      }
      return yaAsociado;
    }

    final interprete = _primeroQueReconoce(texto);
    if (interprete == null) {
      throw StateError('Ningún intérprete reconoce el código');
    }
    final codigo = CodigoProducto(
      const Uuid().v4(),
      interprete.formatoDe(texto),
      texto,
    );
    producto.agregarCodigo(codigo);
    try {
      await _productos.guardar(tienda, producto);
    } catch (_) {
      producto.quitarCodigo(codigo);
      rethrow;
    }
    return codigo;
  }

  /// Imprime [copias] etiquetas de cada producto (CUS-18, opt "Etiquetas",
  /// pasos 43 a 49). Rechaza con [ExcepcionCopiasNoValidas] si [copias] no está
  /// entre 1 y [ConfiguracionInventario.maximoCopiasEtiquetas] (DI-35).
  Future<void> imprimirEtiquetas(
    Tienda tienda,
    List<Producto> productos,
    int copias,
  ) async {
    final etiquetas = await generarEtiquetas(tienda, productos, copias);
    await _impresion.imprimir(etiquetas);
  }

  /// Arma una [Etiqueta] por copia de cada producto; no se guardan (DA-40). Al
  /// producto sin códigos se le crea y guarda uno QR "GIP:" + código interno,
  /// todos en una sola transacción (DA-41, RNF-04). La etiqueta lleva el código
  /// QR del producto o, si no tiene, el primero que tenga (DI-35).
  Future<List<Etiqueta>> generarEtiquetas(
    Tienda tienda,
    List<Producto> productos,
    int copias,
  ) async {
    if (copias < 1 || copias > ConfiguracionInventario.maximoCopiasEtiquetas) {
      throw ExcepcionCopiasNoValidas(
        ConfiguracionInventario.maximoCopiasEtiquetas,
      );
    }
    if (productos.isEmpty) {
      throw StateError('No hay productos para imprimir etiquetas');
    }

    final conCodigoNuevo = <Producto, CodigoProducto>{};
    for (final producto in productos) {
      if (producto.getCodigos().isNotEmpty) continue;
      conCodigoNuevo[producto] = CodigoProducto(
        const Uuid().v4(),
        FormatoCodigo.qr,
        'GIP:${producto.getCodigo()}',
      );
    }
    if (conCodigoNuevo.isNotEmpty) {
      conCodigoNuevo.forEach((p, c) => p.agregarCodigo(c));
      try {
        await _unidadTrabajo.ejecutar(() async {
          for (final producto in conCodigoNuevo.keys) {
            await _productos.guardar(tienda, producto);
          }
        });
      } catch (_) {
        conCodigoNuevo.forEach((p, c) => p.quitarCodigo(c));
        rethrow;
      }
    }

    return [
      for (final producto in productos)
        for (var i = 0; i < copias; i++)
          Etiqueta(producto, _codigoParaEtiqueta(producto)),
    ];
  }

  CodigoProducto _codigoParaEtiqueta(Producto producto) {
    final codigos = producto.getCodigos();
    return codigos.firstWhere(
      (c) => c.getFormato() == FormatoCodigo.qr,
      orElse: () => codigos.first,
    );
  }

  InterpreteCodigo? _primeroQueReconoce(String lectura) =>
      _interpretes.where((i) => i.reconoce(lectura)).firstOrNull;

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
