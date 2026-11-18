import 'package:gip/business/componentes/gestion_inventario/interprete_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/formato_codigo.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_producto_repositorio.dart';

/// Códigos EAN-13, EAN-8 y UPC-A: valida el dígito de control y busca con
/// buscarPorCodigoProducto (CUS-17, RF-06). Va primero en
/// `ServicioCatalogo.interpretes`.
class InterpreteCodigoBarras implements InterpreteCodigo {
  InterpreteCodigoBarras(this._productos);

  final IProductoRepositorio _productos;

  static final _soloDigitos = RegExp(r'^\d+$');

  /// Verdadero si [lectura] tiene 8, 12 o 13 dígitos y el último es el dígito
  /// de control correcto (GS1: de derecha a izquierda, sin contar el de
  /// control, los dígitos pesan 3, 1, 3, 1…). Lo usa también
  /// `InterpreteCodigoQR` para reconocer lo que no es un EAN ni un UPC.
  static bool esCodigoBarrasValido(String lectura) {
    if (!const {8, 12, 13}.contains(lectura.length) ||
        !_soloDigitos.hasMatch(lectura)) {
      return false;
    }
    final digitos = lectura.codeUnits.map((c) => c - 48).toList();
    final control = digitos.removeLast();
    var suma = 0;
    for (var i = 0; i < digitos.length; i++) {
      final desdeLaDerecha = digitos.length - 1 - i;
      suma += digitos[i] * (desdeLaDerecha.isEven ? 3 : 1);
    }
    return (10 - suma % 10) % 10 == control;
  }

  /// 8, 12 o 13 dígitos con dígito de control válido.
  @override
  bool reconoce(String lectura) => esCodigoBarrasValido(lectura);

  /// Llama a productos.buscarPorCodigoProducto(tienda, lectura).
  @override
  Future<Producto?> buscar(Tienda tienda, String lectura) =>
      _productos.buscarPorCodigoProducto(tienda, lectura);

  /// 13 dígitos → EAN-13, 8 → EAN-8, 12 → UPC-A. Solo se llama con una
  /// lectura que este intérprete reconoce.
  @override
  FormatoCodigo formatoDe(String lectura) {
    if (!reconoce(lectura)) {
      throw ArgumentError.value(lectura, 'lectura', 'no es un EAN ni un UPC');
    }
    return switch (lectura.length) {
      13 => FormatoCodigo.ean13,
      8 => FormatoCodigo.ean8,
      _ => FormatoCodigo.upca,
    };
  }
}
