import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/formato_exportacion.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/opcion_con_icono.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/negocio/exportar_view.dart';
import 'package:gip/presentation/negocio/exportar_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'datos_alertas.dart';
import 'exportar_falsos.dart';

void main() {
  const movil = Size(360, 640);
  const web = Size(1280, 800);

  late ExportarDatosFalso coordinador;
  late ExportarViewModel vm;

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(FormatoExportacion.excel);
    registerFallbackValue(propietariaAlertas.usuario);
  });

  Future<void> abrir(
    WidgetTester tester,
    Size tamano, {
    UsuarioActivo? usuario,
    Future<String> Function()? alExportar,
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    coordinador = ExportarDatosFalso();
    when(() => coordinador.exportar(any(), any(), any(), any(), any()))
        .thenAnswer((invocacion) async {
          if (invocacion.positionalArguments[4] == empleadoAlertas.usuario) {
            throw const ExcepcionSoloPropietario();
          }
          return alExportar != null
              ? alExportar()
              : 'gip-2026-11-01_a_2026-11-15.xlsx';
        });
    vm = ExportarViewModel(
      coordinador,
      usuario ?? propietariaAlertas,
      reloj: () => DateTime(2026, 11, 15, 9),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: ChangeNotifierProvider.value(
          value: vm,
          child: const ExportarView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> exportar(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('exportar_boton')));
    await tester.pumpAndSettle();
  }

  for (final (nombre, tamano) in [('móvil', movil), ('web', web)]) {
    testWidgets('$nombre: muestra el periodo, los formatos y lo que incluye', (
      tester,
    ) async {
      await abrir(tester, tamano);

      expect(tester.takeException(), isNull);
      expect(find.text('Exportar datos'), findsWidgets);
      expect(find.text('Desde'), findsOneWidget);
      expect(find.text('Hasta'), findsOneWidget);
      // Mes actual: del día 1 a hoy.
      expect(find.text('1 nov. 2026'), findsOneWidget);
      expect(find.text('15 nov. 2026'), findsOneWidget);
      expect(find.text('Excel'), findsOneWidget);
      expect(find.text('.xlsx · para abrir y sumar'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('para otro programa'), findsOneWidget);
      expect(find.byKey(const Key('exportar_incluye')), findsOneWidget);
      expect(find.text('Inventario con su existencia'), findsOneWidget);
      expect(find.text('Ventas del periodo y formas de pago'), findsOneWidget);
      expect(find.text('Fiados y abonos'), findsOneWidget);
      expect(find.text('Exportar'), findsOneWidget);
      expect(find.byKey(const Key('exportar_listo')), findsNothing);
    });

    testWidgets('$nombre: Excel viene elegido y se puede cambiar a CSV', (
      tester,
    ) async {
      await abrir(tester, tamano);

      OpcionConIcono opcion(String clave) =>
          tester.widget(find.byKey(Key('exportar_formato_$clave')));
      expect(opcion('excel').elegida, isTrue);
      expect(opcion('csv').elegida, isFalse);

      await tester.tap(find.byKey(const Key('exportar_formato_csv')));
      await tester.pumpAndSettle();

      expect(opcion('excel').elegida, isFalse);
      expect(opcion('csv').elegida, isTrue);
      expect(vm.formato, FormatoExportacion.csv);
    });

    testWidgets('$nombre: Exportar llama al coordinador y muestra el nombre', (
      tester,
    ) async {
      await abrir(tester, tamano);

      await exportar(tester);

      final args = verify(
        () => coordinador.exportar(
          captureAny(),
          captureAny(),
          captureAny(),
          captureAny(),
          captureAny(),
        ),
      ).captured;
      expect(args[1], DateTime(2026, 11));
      expect(args[2], DateTime(2026, 11, 16));
      expect(args[3], FormatoExportacion.excel);
      expect(tester.takeException(), isNull);
      expect(
        find.text('Datos exportados: gip-2026-11-01_a_2026-11-15.xlsx'),
        findsOneWidget,
      );
    });

    testWidgets('$nombre: los campos, formatos y el botón miden 44 px o más', (
      tester,
    ) async {
      await abrir(tester, tamano);

      for (final clave in [
        'exportar_desde',
        'exportar_hasta',
        'exportar_formato_excel',
        'exportar_formato_csv',
        'exportar_boton',
      ]) {
        expect(
          tester.getSize(find.byKey(Key(clave))).height,
          greaterThanOrEqualTo(44),
          reason: clave,
        );
      }
    });

    testWidgets('$nombre: hasta antes de desde avisa y no deja exportar', (
      tester,
    ) async {
      await abrir(tester, tamano);

      vm
        ..elegirDesde(DateTime(2026, 11, 10))
        ..elegirHasta(DateTime(2026, 11, 9));
      await tester.pumpAndSettle();

      expect(
        find.text('La fecha inicial no puede ser posterior a la final'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<BotonPrimario>(find.byKey(const Key('exportar_boton')))
            .onPressed,
        isNull,
      );
      verifyNever(
        () => coordinador.exportar(any(), any(), any(), any(), any()),
      );
    });

    testWidgets('$nombre: el empleado ve que es solo del propietario', (
      tester,
    ) async {
      await abrir(tester, tamano, usuario: empleadoAlertas);

      await exportar(tester);

      expect(
        find.text('Esta consulta es solo para el propietario'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('exportar_listo')), findsNothing);
    });

    testWidgets('$nombre: mientras exporta muestra el avance y bloquea', (
      tester,
    ) async {
      final espera = Completer<String>();
      await abrir(tester, tamano, alExportar: () => espera.future);

      await tester.tap(find.byKey(const Key('exportar_boton')));
      await tester.pump();

      expect(vm.exportando, isTrue);
      expect(
        tester
            .widget<BotonPrimario>(find.byKey(const Key('exportar_boton')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OpcionConIcono>(
              find.byKey(const Key('exportar_formato_csv')),
            )
            .onTap,
        isNull,
      );

      espera.complete('listo.xlsx');
      await tester.pumpAndSettle();
      expect(find.text('Datos exportados: listo.xlsx'), findsOneWidget);
    });

    testWidgets('$nombre: tocar Desde abre el selector y cambia el día', (
      tester,
    ) async {
      await abrir(tester, tamano);

      await tester.tap(find.byKey(const Key('exportar_desde')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('10'),
        ),
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(vm.desde, DateTime(2026, 11, 10));
      expect(find.text('10 nov. 2026'), findsOneWidget);
    });
  }

  testWidgets('en CSV el mensaje dice que son tres archivos', (tester) async {
    await abrir(
      tester,
      movil,
      alExportar: () async => 'gip-2026-11-01_a_2026-11-15',
    );

    await tester.tap(find.byKey(const Key('exportar_formato_csv')));
    await tester.pumpAndSettle();
    await exportar(tester);

    expect(
      find.text(
        'Datos exportados: gip-2026-11-01_a_2026-11-15 (3 archivos CSV)',
      ),
      findsOneWidget,
    );
  });

  testWidgets('móvil: el botón queda fijo abajo y no hay nota lateral', (
    tester,
  ) async {
    await abrir(tester, movil);

    final boton = tester.getRect(find.byKey(const Key('exportar_boton')));
    expect(boton.bottom, greaterThan(movil.height - 100));
    expect(boton.width, greaterThan(movil.width - 40));
    expect(find.byKey(const Key('exportar_nota')), findsNothing);
  });

  testWidgets('móvil: el resultado sale arriba y a la vista, sin desplazarse', (
    tester,
  ) async {
    await abrir(tester, movil);

    await exportar(tester);

    final listo = tester.getRect(find.byKey(const Key('exportar_listo')));
    final desde = tester.getRect(find.byKey(const Key('exportar_desde')));
    expect(listo.bottom, lessThan(desde.top));
    expect(listo.top, greaterThanOrEqualTo(0));
    expect(listo.bottom, lessThan(movil.height));
  });

  testWidgets('web: el resultado y la nota van a la derecha del formulario', (
    tester,
  ) async {
    await abrir(tester, web);

    await exportar(tester);

    final formulario = tester.getRect(find.byKey(const Key('exportar_desde')));
    final listo = tester.getRect(find.byKey(const Key('exportar_listo')));
    final nota = tester.getRect(find.byKey(const Key('exportar_nota')));
    expect(listo.left, greaterThan(formulario.right));
    expect(nota.left, greaterThan(formulario.right));
    expect(nota.top, greaterThan(listo.top));
    expect(
      find.text(
        'Si el periodo no es válido (por ejemplo, “hasta” antes de “desde”), '
        'se avisa antes de exportar.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('web: el botón Exportar queda a la derecha del formulario', (
    tester,
  ) async {
    await abrir(tester, web);

    final boton = tester.getRect(find.byKey(const Key('exportar_boton')));
    final formato = tester.getRect(
      find.byKey(const Key('exportar_formato_excel')),
    );
    expect(boton.width, lessThan(300));
    expect(boton.top, greaterThan(formato.bottom));
  });
}
