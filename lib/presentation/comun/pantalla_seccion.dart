import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Pantalla simple de una sección principal: [EncabezadoPantalla] con el
/// [titulo] y, si hay, el [saludo] o la fecha como línea de contexto. Debajo
/// van los [hijos] de la sección, si los hay.
class PantallaSeccion extends StatelessWidget {
  const PantallaSeccion({
    super.key,
    required this.titulo,
    this.saludo,
    this.hijos = const [],
  });

  final String titulo;
  final String? saludo;

  /// Contenido debajo del título. Opcional: sin él solo se ve el encabezado.
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    final web = FormaGip.esWeb(context);
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: ListView(
              padding: web
                  ? const EdgeInsets.fromLTRB(44, 36, 44, 48)
                  : const EdgeInsets.fromLTRB(16, 28, 16, 24),
              children: [
                EncabezadoPantalla(titulo: titulo, contexto: saludo),
                ...hijos,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
