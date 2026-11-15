import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/menu_lateral.dart';

/// Barra inferior del móvil (rediseño): 76 px con las 5 secciones; la activa
/// en `primario` con el ícono dentro de una píldora `primarioSuave`.
class BarraInferior extends StatelessWidget {
  const BarraInferior({
    super.key,
    required this.secciones,
    required this.indiceActivo,
    required this.onSeccion,
  });

  static const alto = 76.0;

  final List<SeccionNavegacion> secciones;
  final int indiceActivo;
  final ValueChanged<int> onSeccion;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Material(
      color: esquema.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: esquema.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: alto,
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              label: 'Secciones',
              child: Row(
                children: [
                  for (var i = 0; i < secciones.length; i++)
                    Expanded(
                      child: _Item(
                        seccion: secciones[i],
                        activa: i == indiceActivo,
                        onTap: () => onSeccion(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.seccion,
    required this.activa,
    required this.onTap,
  });

  final SeccionNavegacion seccion;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final color = activa ? esquema.primary : esquema.onSurfaceVariant;
    final icono = IconTheme.merge(
      data: IconThemeData(color: color, size: 22),
      child: seccion.icono(22),
    );
    return Semantics(
      selected: activa,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              key: activa ? const Key('barra_inferior_activa') : null,
              width: 56,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: activa ? esquema.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: icono,
            ),
            const SizedBox(height: 4),
            Text(
              seccion.etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
