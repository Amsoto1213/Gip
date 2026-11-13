import 'package:flutter_test/flutter_test.dart';
import 'package:gip/main.dart';

void main() {
  testWidgets('La app arranca y muestra el nombre del GIP', (tester) async {
    await tester.pumpWidget(const GipApp());

    expect(find.text('GIP — Gestor de Inventario Predictivo'), findsOneWidget);
  });
}
