import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/alerta_reabastecimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';

/// Datos de prueba de la pantalla Alertas de surtido.
final tiendaAlertas = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');

final UsuarioActivo propietariaAlertas = (
  usuario: Administrador('u1', 'Carmen', '1000000001'),
  tienda: tiendaAlertas,
);

final UsuarioActivo empleadoAlertas = (
  usuario: Empleado('u2', 'Luis', '1000000002'),
  tienda: tiendaAlertas,
);

Decimal d(String v) => Decimal.parse(v);

Producto productoAlertas(String id, String nombre) =>
    Producto(id, id, nombre, UnidadMedida.unidad, null, d('3000'));

final coco = productoAlertas('p1', 'Coco');
final platano = productoAlertas('p2', 'Plátano');
final aceite = productoAlertas('p3', 'Aceite 1 L');

AlertaReabastecimiento alertaDe(
  Producto producto,
  String hay,
  String vende,
  String dias, {
  bool provisional = false,
}) => AlertaReabastecimiento(
  'a-${producto.getId()}',
  ItemInventario('i-${producto.getId()}', producto, d(hay)),
  DateTime(2026, 11, 15),
  d(hay),
  d(vende),
  d(dias),
  provisional,
);

/// Las tres alertas del mockup `Alertas`.
final alertasDelMockup = [
  alertaDe(coco, '2', '2.3', '0.86'),
  alertaDe(platano, '18', '9.5', '1.89'),
  alertaDe(aceite, '8', '2', '4', provisional: true),
];

/// Coco se pidió agotado tres veces.
final ventasPerdidasDelMockup = [
  VentaPerdida('v1', coco, DateTime(2026, 11, 14, 18, 5)),
  VentaPerdida('v2', coco, DateTime(2026, 11, 12, 9, 40)),
  VentaPerdida('v3', coco, DateTime(2026, 11, 10, 12)),
];
