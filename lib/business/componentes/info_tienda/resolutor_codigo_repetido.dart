import 'package:gip/business/componentes/info_tienda/resolutor_conflicto.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/interfaces/gestion_inventario/i_producto_repositorio.dart';
import 'package:gip/transversal/errores/errores_conciliacion.dart';

/// Resuelve CODIGO_REPETIDO: el propietario escoge qué productos pierden el
/// código repetido (DA-66).
class ResolutorCodigoRepetido implements ResolutorConflicto {
  ResolutorCodigoRepetido(this._productos);

  final IProductoRepositorio _productos;

  /// Verdadero si el tipo es CODIGO_REPETIDO.
  @override
  bool admite(ConflictoSincronizacion conflicto) =>
      conflicto.getTipo() == TipoConflicto.codigoRepetido;

  /// Los ids del conflicto son los de los productos. Por cada producto de
  /// [idsElegidos] (`productos.buscarPorId`): si comparte un código de barras
  /// o QR con otro producto del conflicto, llama a `producto.quitarCodigo` y
  /// `productos.quitarCodigo`; si comparte el código interno, a
  /// `producto.cambiarCodigoInterno(codigo + '-' + n)`, con el primer `n` desde
  /// 2 que no esté en uso; y guarda con `productos.guardar`.
  ///
  /// Qué se comparte se calcula antes de cambiar nada, para que quitarle un
  /// código a un producto no cambie lo que ve el siguiente. Los productos que
  /// no se eligieron no cambian, y uno elegido que ya no comparte nada (se
  /// corrigió en otro equipo) tampoco. Sin ningún producto elegido lanza
  /// [ExcepcionDecisionIncompleta]; si falta alguno del conflicto, o se
  /// piden productos que no son del conflicto, no cambia nada (DI-45).
  @override
  Future<void> resolver(
    Tienda tienda,
    ConflictoSincronizacion conflicto,
    List<String> idsElegidos,
  ) async {
    final productos = <Producto>[];
    for (final id in conflicto.getIdsRegistros()) {
      final producto = await _productos.buscarPorId(tienda, id);
      if (producto == null) {
        throw const ExcepcionRegistrosDelConflictoNoEncontrados();
      }
      productos.add(producto);
    }
    final elegidos = [
      for (final p in productos)
        if (idsElegidos.contains(p.getId())) p,
    ];
    if (elegidos.isEmpty) {
      throw const ExcepcionDecisionIncompleta(
        'Marque los productos que pierden el código repetido',
      );
    }

    // Lo repetido, mirado antes de cambiar nada.
    final repetidos = {
      for (final p in elegidos)
        p.getId(): (
          barras: [
            for (final c in p.getCodigos())
              if (productos.any(
                (o) =>
                    o != p &&
                    o.getCodigos().any((x) => x.getValor() == c.getValor()),
              ))
                c,
          ],
          interno: productos.any(
            (o) => o != p && o.getCodigo() == p.getCodigo(),
          ),
        ),
    };

    for (final producto in elegidos) {
      final repetido = repetidos[producto.getId()]!;
      if (repetido.barras.isEmpty && !repetido.interno) continue;
      for (final codigo in repetido.barras) {
        producto.quitarCodigo(codigo);
        await _productos.quitarCodigo(tienda, producto, codigo);
      }
      if (repetido.interno) {
        producto.cambiarCodigoInterno(
          await _codigoLibre(tienda, producto.getCodigo()),
        );
      }
      producto.setActualizadoEn(DateTime.now());
      await _productos.guardar(tienda, producto);
    }
  }

  /// `codigo-2`, `codigo-3`… el primero que ningún producto tenga.
  Future<String> _codigoLibre(Tienda tienda, String codigo) async {
    var n = 2;
    while (await _productos.buscarPorCodigo(tienda, '$codigo-$n') != null) {
      n++;
    }
    return '$codigo-$n';
  }
}
