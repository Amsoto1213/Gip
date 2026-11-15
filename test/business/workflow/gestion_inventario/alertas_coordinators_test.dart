import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/gestion_inventario/consumo_promedio_simple.dart';
import 'package:gip/business/componentes/gestion_inventario/servicio_alertas.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/gestion_inventario/entrada_mercancia.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/business/workflow/gestion_inventario/consultar_alertas_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/generar_alertas_diarias_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';

import '../../componentes/gestion_inventario/fakes_alertas.dart';
import '../../componentes/gestion_inventario/fakes_catalogo.dart';
import '../../componentes/gestion_inventario/fakes_inventario.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final propietaria = Administrador('u1', 'Carmen', '1000000001');
  final empleado = Empleado('u2', 'Luis', '1000000002');
  final hoy = DateTime(2026, 11, 15, 6);
  Decimal d(String v) => Decimal.parse(v);

  late MovimientoRepositorioFalso movimientos;
  late VentaPerdidaRepositorioFalso perdidas;
  late AlertaRepositorioFalso alertas;
  late GenerarAlertasDiariasCoordinator generar;
  late ConsultarAlertasCoordinator consultar;
  late Producto coco;

  setUp(() async {
    final items = InventarioRepositorioFalso();
    movimientos = MovimientoRepositorioFalso();
    perdidas = VentaPerdidaRepositorioFalso();
    alertas = AlertaRepositorioFalso();
    final servicio = ServicioAlertas(
      items,
      movimientos,
      perdidas,
      alertas,
      ConsumoPromedioSimple(),
      7,
    );
    generar = GenerarAlertasDiariasCoordinator(servicio);
    consultar = ConsultarAlertasCoordinator(
      servicio,
      ServicioAcceso(AutenticacionFalsa(), SesionLocalFalsa()),
    );

    coco = Producto('p1', 'C1', 'Coco', UnidadMedida.unidad, null, d('3000'));
    final item = ItemInventario('i1', coco, d('2'));
    await items.guardarItem(tienda, item);
    final fecha = DateTime(2026, 11, 10);
    movimientos.de(tienda)
      ..add(
        EntradaMercancia(
          'e1',
          item,
          d('20'),
          DateTime(2026, 9, 1),
          d('1'),
          null,
        ),
      )
      ..add(
        SalidaVenta(
          's1',
          item,
          d('-30'),
          fecha,
          Venta('v1', const [], d('0'), fecha),
          d('3000'),
          null,
        ),
      );
    perdidas.agregar(tienda, VentaPerdida('vp1', coco, DateTime(2026, 11, 3)));
  });

  test('CUS-24: ejecutar genera y guarda las alertas del día', () async {
    await generar.ejecutar(tienda, hoy);

    final guardadas = await alertas.listarPorFecha(
      tienda,
      DateTime(2026, 11, 15),
    );
    expect(guardadas, hasLength(1));
    expect(guardadas.single.getItem().getProducto().getNombre(), 'Coco');
  });

  group('CUS-05', () {
    test('el propietario consulta las alertas ya calculadas', () async {
      expect(
        await consultar.consultarAlertas(tienda, hoy, propietaria),
        isEmpty,
      );

      await generar.ejecutar(tienda, hoy);

      expect(
        await consultar.consultarAlertas(tienda, hoy, propietaria),
        hasLength(1),
      );
    });

    test('el propietario consulta las ventas perdidas del periodo', () async {
      final encontradas = await consultar.consultarVentasPerdidas(
        tienda,
        DateTime(2026, 10, 16),
        DateTime(2026, 11, 15),
        propietaria,
      );
      expect(encontradas.map((v) => v.getId()), ['vp1']);
    });

    test('al empleado se le niegan las alertas', () async {
      await generar.ejecutar(tienda, hoy);

      await expectLater(
        consultar.consultarAlertas(tienda, hoy, empleado),
        throwsA(isA<ExcepcionSoloPropietario>()),
      );
    });

    test('al empleado se le niegan las ventas perdidas', () async {
      await expectLater(
        consultar.consultarVentasPerdidas(
          tienda,
          DateTime(2026, 10, 16),
          DateTime(2026, 11, 15),
          empleado,
        ),
        throwsA(isA<ExcepcionSoloPropietario>()),
      );
    });
  });
}
