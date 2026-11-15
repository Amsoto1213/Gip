import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/negocio/margen_view.dart';
import 'package:gip/presentation/negocio/margen_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'datos_alertas.dart';
import 'margen_falsos.dart';

void main() {
  const movil = Size(360, 640);
  const web = Size(1280, 800);

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(propietariaAlertas.usuario);
  });

  Future<void> abrir(
    WidgetTester tester,
    Size tamano, {
    Map<Producto, Decimal?>? margenes,
    UsuarioActivo? usuario,
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final coordinador = ConsultarMargenFalso();
    when(
      () => coordinador.consultarMargen(any(), any(), any(), any()),
    ).thenAnswer((invocacion) async {
      if (invocacion.positionalArguments[3] == empleadoAlertas.usuario) {
        throw const ExcepcionSoloPropietario();
      }
      return margenes ?? {coco: d('61800'), aceite: d('28600'), platano: null};
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: ChangeNotifierProvider(
          create: (_) => MargenViewModel(
            coordinador,
            usuario ?? propietariaAlertas,
            reloj: () => DateTime(2026, 11, 11, 9),
          )..cargar(),
          child: const MargenView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (nombre, tamano) in [('móvil', movil), ('web', web)]) {
    testWidgets('$nombre: muestra la ganancia por producto', (tester) async {
      await abrir(tester, tamano);

      expect(tester.takeException(), isNull);
      expect(find.text('Ganancia por producto'), findsWidgets);
      expect(find.text('Coco'), findsOneWidget);
      expect(find.text('\$ 61.800'), findsOneWidget);
      expect(find.text('\$ 28.600'), findsOneWidget);
      expect(find.text('Plátano'), findsOneWidget);
      // Total de los completos; 2 con ganancia + 1 incompleto.
      expect(find.byKey(const Key('margen_total')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('margen_total'))).data,
        '\$ 90.400',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('margen_con_ventas'))).data,
        '3',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('margen_sin_costo'))).data,
        '1',
      );
    });

    testWidgets('$nombre: el producto sin costo sale en rojo', (tester) async {
      await abrir(tester, tamano);

      final pildora = tester.widget<PildoraEstado>(
        find.widgetWithText(PildoraEstado, 'Sin costo'),
      );
      expect(pildora.tono, TonoEstado.error);
      await tester.scrollUntilVisible(
        find.byKey(const Key('margen_aviso_sin_costo')),
        200,
      );
      expect(find.byKey(const Key('margen_aviso_sin_costo')), findsOneWidget);
      expect(find.byType(TarjetaAviso), findsOneWidget);
    });

    testWidgets('$nombre: los periodos miden 44 px o más', (tester) async {
      await abrir(tester, tamano);

      for (var i = 0; i < 4; i++) {
        expect(
          tester.getSize(find.byKey(Key('margen_periodo_$i'))).height,
          greaterThanOrEqualTo(44),
        );
      }
    });

    testWidgets('$nombre: sin ventas lo dice y no hay aviso', (tester) async {
      await abrir(tester, tamano, margenes: {});

      expect(find.text('No hay ventas en este periodo'), findsOneWidget);
      expect(find.byKey(const Key('margen_aviso_sin_costo')), findsNothing);
    });

    testWidgets('$nombre: el empleado ve que es solo del propietario', (
      tester,
    ) async {
      await abrir(tester, tamano, usuario: empleadoAlertas);

      expect(
        find.text('Esta consulta es solo para el propietario'),
        findsOneWidget,
      );
      expect(find.text('Coco'), findsNothing);
    });
  }

  testWidgets('elegir Hoy consulta de nuevo', (tester) async {
    await abrir(tester, movil);

    await tester.tap(find.byKey(const Key('margen_periodo_0')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Coco'), findsOneWidget);
  });
}
