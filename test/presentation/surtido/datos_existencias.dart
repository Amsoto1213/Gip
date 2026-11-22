import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_inventario/ajuste_conteo.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/merma.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

import 'existencias_falsos.dart';

/// Datos de las pruebas de Existencias (CUS-25), como el mockup
/// `mExistencias`.
final tiendaExistencias = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');

Decimal d(String v) => Decimal.parse(v);

/// "Ahora" de las pruebas: martes 17 de noviembre de 2026, 6:00 p. m. local.
DateTime ahoraExistencias() => DateTime(2026, 11, 17, 18);

/// Una hora local de [dia] de noviembre de 2026, guardada en UTC.
DateTime noviembre(int dia, int hora, [int minuto = 0]) =>
    DateTime(2026, 11, dia, hora, minuto).toUtc();

final aceite = Producto(
  'p-aceite',
  'P014',
  'Aceite 1 L',
  UnidadMedida.unidad,
  d('8600'),
  d('9900'),
);
final arroz = Producto(
  'p-arroz',
  'P001',
  'Arroz 500 g',
  UnidadMedida.unidad,
  null,
  d('2800'),
);
final queso = Producto(
  'p-queso',
  'P045',
  'Queso costeño',
  UnidadMedida.libra,
  null,
  d('9000'),
);

final itemAceite = ItemInventario('i-aceite', aceite, d('32'));
final itemArroz = ItemInventario('i-arroz', arroz, d('46'));
final itemQueso = ItemInventario('i-queso', queso, d('0'));

/// En el orden del coordinador (por nombre).
List<ItemInventario> itemsExistencias() => [itemAceite, itemArroz, itemQueso];

/// Historial del aceite: 4 en los últimos 30 días (uno anulado) y uno viejo.
List<MovimientoInventario> movimientosAceite() => [
  EntradaMercancia(
    'e-hoy',
    itemAceite,
    d('24'),
    noviembre(17, 16, 10),
    d('8600'),
    'FV-10231',
  ),
  SalidaVenta(
    's-hoy',
    itemAceite,
    d('-1'),
    noviembre(17, 10, 15),
    'v1',
    d('9900'),
    d('8600'),
  ),
  AjusteConteo('a-ayer', itemAceite, d('-1'), noviembre(16, 19, 40), d('9')),
  Merma('m-anulada', itemAceite, d('-2'), noviembre(9, 8), MotivoMerma.vencido)
    ..setEstado(EstadoMovimiento.anulado),
  EntradaMercancia(
    'e-vieja',
    itemAceite,
    d('10'),
    DateTime(2026, 9, 1, 9).toUtc(),
    d('8000'),
    null,
  ),
];

/// Coordinador falso con los tres productos y el historial del aceite; el
/// arroz y el queso no tienen movimientos.
ConsultarExistenciasFalso coordinadorExistencias() => ConsultarExistenciasFalso(
  items: itemsExistencias(),
  movimientos: {aceite.getId(): movimientosAceite()},
);
