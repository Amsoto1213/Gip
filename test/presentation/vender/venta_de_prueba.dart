import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/pagos/procesador_nequi.dart';
import 'package:gip/business/componentes/pagos/procesador_pago_contado.dart';
import 'package:gip/business/componentes/pagos/servicio_ventas.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/workflow/pagos/registrar_venta_coordinator.dart';

import '../../business/componentes/gestion_caja/fakes_caja.dart';
import '../../business/componentes/gestion_inventario/fakes_catalogo.dart';
import '../../business/componentes/gestion_inventario/fakes_inventario.dart';
import '../../business/componentes/pagos/fakes_pagos.dart';

Decimal d(String v) => Decimal.parse(v);

final tiendaPrueba = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');

/// RegistrarVentaCoordinator real sobre repositorios en memoria, con tres
/// productos: arroz (stock 10, $ 2.800), café (21, $ 8.900) y queso (0).
class VentaDePrueba {
  VentaDePrueba._(
    this.coordinador,
    this.items,
    this.ventas,
    this.cajas,
    this.arroz,
    this.cafe,
    this.queso,
  );

  final RegistrarVentaCoordinator coordinador;
  final InventarioRepositorioFalso items;
  final VentaRepositorioFalso ventas;
  final CajaRepositorioFalso cajas;
  final Producto arroz;
  final Producto cafe;
  final Producto queso;

  static Future<VentaDePrueba> crear() async {
    final items = InventarioRepositorioFalso();
    final movimientos = MovimientoRepositorioFalso();
    final ventas = VentaRepositorioFalso();
    final cajas = CajaRepositorioFalso();
    final unidad = UnidadTrabajoFalsa([items, movimientos, ventas, cajas]);
    final inventario = ServicioInventario(items, movimientos, d('5'), unidad);
    final servicio = ServicioVentas(
      inventario,
      [ProcesadorPagoContado(ServicioCaja(cajas)), ProcesadorNequi()],
      ventas,
      unidad,
    );
    Producto p(String id, String nombre, String precio) =>
        Producto(id, id, nombre, UnidadMedida.unidad, null, d(precio));
    final arroz = p('arroz', 'Arroz 500 g', '2800');
    final cafe = p('cafe', 'Café molido 250 g', '8900');
    final queso = p('queso', 'Queso costeño', '9000');
    await items.guardarItem(tiendaPrueba, ItemInventario('i1', arroz, d('10')));
    await items.guardarItem(tiendaPrueba, ItemInventario('i2', cafe, d('21')));
    await items.guardarItem(tiendaPrueba, ItemInventario('i3', queso, d('0')));
    return VentaDePrueba._(
      RegistrarVentaCoordinator(servicio),
      items,
      ventas,
      cajas,
      arroz,
      cafe,
      queso,
    );
  }
}
