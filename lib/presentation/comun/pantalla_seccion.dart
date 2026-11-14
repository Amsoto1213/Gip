import 'package:flutter/material.dart';

/// Encabezado de una sección principal: saludo o fecha opcional arriba y el
/// título en Archivo 800 (mockups `Main` y `mNegocio`).
class PantallaSeccion extends StatelessWidget {
  const PantallaSeccion({super.key, required this.titulo, this.saludo});

  final String titulo;
  final String? saludo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            if (saludo != null)
              Text(
                saludo!,
                style: tema.textTheme.bodyLarge?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            Semantics(
              header: true,
              child: Text(titulo, style: tema.textTheme.headlineLarge),
            ),
          ],
        ),
      ),
    );
  }
}
