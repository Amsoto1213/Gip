import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';

/// Una opción de [SelectorFiltro].
typedef OpcionFiltro<T> = ({T valor, String etiqueta});

/// Filtro de una lista en píldoras ("Todos", "Contados", "Sin contar"…): la
/// elegida va rellena en `navFondo` con texto blanco y las demás con contorno.
/// Solo cambia lo que se ve; no es una acción, por eso no va en verde. Si no
/// caben en una línea, bajan a la siguiente. Cada píldora mide 44 px de alto.
class SelectorFiltro<T> extends StatelessWidget {
  const SelectorFiltro({
    super.key,
    required this.opciones,
    required this.elegido,
    required this.onElegir,
    this.prefijoClave = 'filtro',
  });

  final List<OpcionFiltro<T>> opciones;
  final T elegido;
  final ValueChanged<T> onElegir;

  /// Cada píldora lleva la clave `<prefijoClave>_<índice>`.
  final String prefijoClave;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final extra = tema.extension<ColoresExtraGip>()!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (i, opcion) in opciones.indexed)
          Semantics(
            selected: opcion.valor == elegido,
            button: true,
            child: Material(
              key: Key('${prefijoClave}_$i'),
              color: opcion.valor == elegido ? extra.navFondo : esquema.surface,
              shape: StadiumBorder(
                side: BorderSide(
                  color: opcion.valor == elegido
                      ? extra.navFondo
                      : esquema.outline,
                ),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => onElegir(opcion.valor),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        opcion.etiqueta,
                        style: tema.textTheme.labelLarge?.copyWith(
                          color: opcion.valor == elegido
                              ? esquema.onPrimary
                              : esquema.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
