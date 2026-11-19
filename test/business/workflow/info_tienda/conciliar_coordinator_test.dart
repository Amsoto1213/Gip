import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/workflow/info_tienda/conciliar_coordinator.dart';

import '../../componentes/gestion_caja/fakes_caja.dart';
import '../../componentes/gestion_inventario/fakes_catalogo.dart';
import '../../componentes/gestion_inventario/fakes_inventario.dart';
import '../../componentes/info_tienda/fakes_conciliacion.dart';
import '../../componentes/pagos/fakes_pagos.dart';

import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/info_tienda/servicio_conciliacion.dart';

/// CUS-23: el coordinador solo delega en el servicio y devuelve los conflictos
/// nuevos.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);
  final ahora = DateTime.utc(2026, 11, 19, 20);

  test('ejecutar concilia y devuelve los conflictos nuevos, sin pedir '
      'propietario porque lo corre la app', () async {
    final conflictos = ConflictoRepositorioFalso();
    final movimientos = MovimientoRepositorioFalso();
    final items = InventarioRepositorioFalso();
    final unidad = UnidadTrabajoFalsa([conflictos, movimientos, items]);
    final productos = ProductoRepositorioFalso();
    final huevo = ItemInventario(
      'i1',
      Producto('p1', 'H1', 'Huevo AA', UnidadMedida.unidad, d('400'), d('550')),
      d('0'),
    );
    await items.guardarItem(tienda, huevo);
    final hace2h = ahora.subtract(const Duration(hours: 2));
    final hace1h = ahora.subtract(const Duration(hours: 1));
    for (final (id, f) in [('e1', hace2h), ('e2', hace1h)]) {
      await movimientos.guardar(
        tienda,
        EntradaMercancia(id, huevo, d('24'), f, d('400'), 'FV1'),
      );
    }
    final coordinador = ConciliarCoordinator(
      ServicioConciliacion(
        conflictos,
        movimientos,
        FiadoRepositorioFalso(),
        CajaRepositorioFalso(),
        productos,
        ServicioInventario(items, movimientos, d('5'), unidad, productos),
        unidad,
        const [],
        reloj: () => ahora,
      ),
    );

    final nuevos = await coordinador.ejecutar(
      tienda,
      ahora.subtract(const Duration(hours: 6)),
    );

    expect(nuevos.single.getTipo(), TipoConflicto.posibleDuplicado);
    expect(conflictos.todos(tienda), nuevos);
  });
}
