import 'package:flutter/material.dart';

/// Composition Root del GIP: único lugar que conoce las clases concretas de data/.
/// Por ahora solo arranca una pantalla vacía; los módulos se registran desde composition_root/.
void main() {
  runApp(const GipApp());
}

class GipApp extends StatelessWidget {
  const GipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'GIP',
      home: Scaffold(
        body: Center(child: Text('GIP — Gestor de Inventario Predictivo')),
      ),
    );
  }
}
