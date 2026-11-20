import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/presentation/comun/datos_actualizados.dart';
import 'package:provider/provider.dart';

class _Modelo extends ChangeNotifier {
  int cargas = 0;
  void cargar() => cargas++;
}

void main() {
  Widget montar(DatosActualizados? datos, _Modelo modelo, {Key? clave}) {
    Widget arbol = ChangeNotifierProvider.value(
      value: modelo,
      child: RecargarAlCambiarLosDatos<_Modelo>(
        key: clave,
        alRecargar: (vm) => vm.cargar(),
        child: const Text('pantalla'),
      ),
    );
    if (datos != null) {
      arbol = ChangeNotifierProvider.value(value: datos, child: arbol);
    }
    return MaterialApp(home: arbol);
  }

  test('DatosActualizados cuenta los avisos y avisa a quien escucha', () {
    final datos = DatosActualizados();
    var avisos = 0;
    datos.addListener(() => avisos++);

    datos
      ..avisar()
      ..avisar();

    expect(datos.version, 2);
    expect(avisos, 2);
  });

  testWidgets('cada aviso recarga el view model y dibuja su hijo', (
    tester,
  ) async {
    final datos = DatosActualizados();
    final modelo = _Modelo();
    await tester.pumpWidget(montar(datos, modelo));
    expect(find.text('pantalla'), findsOneWidget);
    expect(modelo.cargas, 0, reason: 'no recarga solo por abrirse');

    datos.avisar();
    await tester.pump();
    datos.avisar();
    await tester.pump();

    expect(modelo.cargas, 2);
  });

  testWidgets('al salir de pantalla deja de escuchar', (tester) async {
    final datos = DatosActualizados();
    final modelo = _Modelo();
    await tester.pumpWidget(montar(datos, modelo));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    datos.avisar();
    await tester.pump();

    expect(modelo.cargas, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin el aviso en el árbol no recarga ni falla', (tester) async {
    final modelo = _Modelo();

    await tester.pumpWidget(montar(null, modelo));

    expect(find.text('pantalla'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
