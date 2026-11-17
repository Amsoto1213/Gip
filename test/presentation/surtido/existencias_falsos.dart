import 'dart:async';

import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/gestion_inventario/consultar_existencias_coordinator.dart';

/// Una consulta de historial que recibió el coordinador falso.
typedef ConsultaMovimientos = ({
  Producto producto,
  DateTime desde,
  DateTime hasta,
});

/// [ConsultarExistenciasCoordinator] en memoria (CUS-25). Sin datos, la
/// tienda no tiene productos.
class ConsultarExistenciasFalso implements ConsultarExistenciasCoordinator {
  ConsultarExistenciasFalso({
    this.items = const [],
    Map<String, List<MovimientoInventario>>? movimientos,
  }) : movimientos = movimientos ?? {};

  /// Lo que devuelve [listarExistencias].
  List<ItemInventario> items;

  /// Historial por id de producto, en cualquier orden.
  final Map<String, List<MovimientoInventario>> movimientos;

  /// Si no es nulo, [listarExistencias] lo lanza.
  Object? fallaListar;

  /// Si no es nulo, [consultarMovimientos] lo lanza.
  Object? fallaMovimientos;

  /// Si no es nulo, [listarExistencias] espera a que se complete.
  Completer<void>? esperaListar;

  int vecesListar = 0;
  final List<ConsultaMovimientos> consultas = [];

  @override
  Future<List<ItemInventario>> listarExistencias(Tienda tienda) async {
    vecesListar++;
    await esperaListar?.future;
    if (fallaListar case final falla?) throw falla;
    return items;
  }

  @override
  Future<List<MovimientoInventario>> consultarMovimientos(
    Tienda tienda,
    Producto producto,
    DateTime desde,
    DateTime hasta,
  ) async {
    consultas.add((producto: producto, desde: desde, hasta: hasta));
    if (fallaMovimientos case final falla?) throw falla;
    return (movimientos[producto.getId()] ?? const [])
        .where(
          (m) => !m.getFecha().isBefore(desde) && m.getFecha().isBefore(hasta),
        )
        .toList()
      ..sort((a, b) => b.getFecha().compareTo(a.getFecha()));
  }
}
