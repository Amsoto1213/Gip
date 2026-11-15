import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/tarjeta_accion.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/negocio/negocio_view.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class IniciarSesionFalso extends Mock implements IniciarSesionCoordinator {}

void main() {
  testWidgets('Cerrar sesión es un botón secundario que sale de la sesión', (
    tester,
  ) async {
    final coordinador = IniciarSesionFalso();
    when(coordinador.cerrarSesion).thenAnswer((_) async {});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => IniciarSesionViewModel(coordinador),
        child: MaterialApp(theme: TemaGip.claro(), home: const NegocioView()),
      ),
    );

    expect(find.text('Negocio'), findsOneWidget);
    expect(
      find.widgetWithText(BotonSecundario, 'Cerrar sesión'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.logout), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('negocio_cerrar_sesion'))).height,
      greaterThanOrEqualTo(44),
    );

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    verify(coordinador.cerrarSesion).called(1);
  });

  testWidgets('tiene la acción Alertas de surtido de 44 px o más', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => IniciarSesionViewModel(IniciarSesionFalso()),
        child: MaterialApp(theme: TemaGip.claro(), home: const NegocioView()),
      ),
    );

    expect(
      find.widgetWithText(TarjetaAccion, 'Alertas de surtido'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('negocio_alertas'))).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('tiene la acción Ganancia por producto de 44 px o más', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => IniciarSesionViewModel(IniciarSesionFalso()),
        child: MaterialApp(theme: TemaGip.claro(), home: const NegocioView()),
      ),
    );

    expect(
      find.widgetWithText(TarjetaAccion, 'Ganancia por producto'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('negocio_ganancia'))).height,
      greaterThanOrEqualTo(44),
    );
  });
}
