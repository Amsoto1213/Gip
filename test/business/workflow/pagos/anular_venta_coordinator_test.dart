import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_inventario.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/pagos/procesador_nequi.dart';
import 'package:gip/business/componentes/pagos/procesador_pago_contado.dart';
import 'package:gip/business/componentes/pagos/servicio_ventas.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/business/workflow/pagos/anular_venta_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';

import '../../componentes/gestion_caja/fakes_caja.dart';
import '../../componentes/gestion_inventario/fakes_catalogo.dart';
import '../../componentes/gestion_inventario/fakes_inventario.dart';
import '../../componentes/pagos/fakes_pagos.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

/// CUS-20: solo el propietario lista y anula ventas (RNF-12, RNF-15).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final propietario = Administrador('2222', 'Carmen', '1000000001');
  final empleado = Empleado('3333', 'Luis', '2');
  Decimal d(String v) => Decimal.parse(v);

  late VentaRepositorioFalso ventasRepo;
  late MovimientoRepositorioFalso movimientos;
  late InventarioRepositorioFalso items;
  late CajaRepositorioFalso cajas;
  late ServicioVentas servicioVentas;
  late AnularVentaCoordinator coordinador;
  late Producto arroz;
  late Venta venta;

  setUp(() async {
    ventasRepo = VentaRepositorioFalso();
    movimientos = MovimientoRepositorioFalso();
    items = InventarioRepositorioFalso();
    cajas = CajaRepositorioFalso();
    final productos = ProductoRepositorioFalso();
    final unidad = UnidadTrabajoFalsa([
      ventasRepo,
      movimientos,
      items,
      cajas,
      productos,
    ]);
    for (final f in [ventasRepo, movimientos, items, cajas]) {
      (f as dynamic).unidad = unidad;
    }
    final inventario = ServicioInventario(
      items,
      movimientos,
      d('5'),
      unidad,
      productos,
    );
    servicioVentas = ServicioVentas(
      inventario,
      [ProcesadorPagoContado(ServicioCaja(cajas)), ProcesadorNequi()],
      ventasRepo,
      unidad,
    );
    coordinador = AnularVentaCoordinator(
      servicioVentas,
      ServicioAcceso(AutenticacionFalsa(), SesionLocalFalsa()),
    );
    arroz = Producto(
      'p1',
      'ARR',
      'Arroz',
      UnidadMedida.unidad,
      d('2000'),
      d('2800'),
    );
    await items.guardarItem(tienda, ItemInventario('i1', arroz, d('10')));
    final lineas = <LineaVenta>[];
    await servicioVentas.agregarLinea(tienda, lineas, arroz, d('3'));
    final total = servicioVentas.calcularTotal(lineas);
    venta = await servicioVentas.confirmar(tienda, lineas, [
      servicioVentas.crearPagoContado(total, total),
    ]);
  });

  final desde = DateTime.now().subtract(const Duration(days: 1));
  final hasta = DateTime.now().add(const Duration(days: 1));

  test('el propietario lista las ventas', () async {
    final lista = await coordinador.listarVentas(
      tienda,
      desde,
      hasta,
      propietario,
    );

    expect(lista, [venta]);
  });

  test('el propietario ve los productos de cada venta', () async {
    final productos = await coordinador.listarProductos(tienda, [
      venta,
    ], propietario);

    expect(productos[venta.getId()]!.single.calcularUnidades(), d('3'));
  });

  test('el propietario anula la venta y recibe la anulación', () async {
    final anulacion = await coordinador.anularVenta(
      tienda,
      venta,
      'Error al cobrar',
      propietario,
    );

    expect(venta.isAnulada(), isTrue);
    expect(anulacion.getMotivo(), 'Error al cobrar');
    expect(anulacion.getUsuarioId(), propietario.getId());
    expect(anulacion.getUsuarioNombre(), propietario.getNombre());
    expect(ventasRepo.anulaciones, [anulacion]);
  });

  test(
    'el empleado no lista, ni ve productos, ni anula: acceso denegado',
    () async {
      await expectLater(
        coordinador.listarVentas(tienda, desde, hasta, empleado),
        throwsA(isA<ExcepcionSoloPropietario>()),
      );
      await expectLater(
        coordinador.listarProductos(tienda, [venta], empleado),
        throwsA(isA<ExcepcionSoloPropietario>()),
      );
      await expectLater(
        coordinador.anularVenta(tienda, venta, 'x', empleado),
        throwsA(isA<ExcepcionSoloPropietario>()),
      );
      expect(venta.isAnulada(), isFalse);
      expect(ventasRepo.anulaciones, isEmpty);
      expect(movimientos.estadosActualizados, isEmpty);
    },
  );
}
