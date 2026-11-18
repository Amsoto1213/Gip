import 'package:gip/business/componentes/gestion_inventario/interprete_codigo.dart';
import 'package:gip/business/componentes/gestion_inventario/interprete_codigo_barras.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_producto_repositorio.dart';

/// Códigos QR (del sistema "GIP:" o de fábrica): busca su texto exacto con
/// buscarPorCodigoProducto (DA-41). Va de último en
/// `ServicioCatalogo.interpretes` porque reconoce cualquier texto que no sea
/// un EAN o UPC válido (CUS-17).
class InterpreteCodigoQR implements InterpreteCodigo {
  InterpreteCodigoQR(this._productos);

  final IProductoRepositorio _productos;

  /// La lectura no es un EAN o UPC válido; se trata como texto de QR.
  @override
  bool reconoce(String lectura) =>
      !InterpreteCodigoBarras.esCodigoBarrasValido(lectura);

  /// Llama a productos.buscarPorCodigoProducto(tienda, lectura), sin quitar
  /// prefijos.
  @override
  Future<Producto?> buscar(Tienda tienda, String lectura) =>
      _productos.buscarPorCodigoProducto(tienda, lectura);

  @override
  FormatoCodigo formatoDe(String lectura) => FormatoCodigo.qr;
}
