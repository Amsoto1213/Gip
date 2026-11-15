import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Una opción de [SelectorFiltro].
typedef OpcionFiltro<T> = ({T valor, String etiqueta});

/// Cómo se dibuja un [SelectorFiltro].
enum EstiloFiltro {
  /// Píldoras sueltas; la elegida rellena en `navFondo` (móvil).
  pildoras,

  /// Pestañas dentro de un grupo `fondo`; la elegida en blanco con sombra
  /// (encabezado de una tabla en la web, `conteo-web.html`).
  pestanas,
}

/// Filtro de una lista ("Todos", "Contados", "Sin contar"…). Solo cambia lo
/// que se ve; no es una acción, por eso no va en verde. Si no caben en una
/// línea, bajan a la siguiente. Cada opción mide 44 px de alto y no toma el
/// foco: tocar una no se lo quita al campo en el que se está escribiendo.
///
/// - [EstiloFiltro.pildoras]: texto de 13 px; la elegida va rellena en
///   `navFondo` con texto blanco y las demás con contorno
///   (`conteo-movil.html`).
/// - [EstiloFiltro.pestanas]: grupo con fondo `fondo` y radio 14; la elegida
///   en `superficie` con sombra y texto 700, las demás sin fondo en
///   `textoSecundario`.
class SelectorFiltro<T> extends StatelessWidget {
  const SelectorFiltro({
    super.key,
    required this.opciones,
    required this.elegido,
    required this.onElegir,
    this.prefijoClave = 'filtro',
    this.estilo = EstiloFiltro.pildoras,
  });

  final List<OpcionFiltro<T>> opciones;
  final T elegido;
  final ValueChanged<T> onElegir;

  /// Cada opción lleva la clave `<prefijoClave>_<índice>`.
  final String prefijoClave;
  final EstiloFiltro estilo;

  @override
  Widget build(BuildContext context) => switch (estilo) {
    EstiloFiltro.pildoras => _pildoras(context),
    EstiloFiltro.pestanas => _pestanas(context),
  };

  Widget _pestanas(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tema.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(FormaGip.radioPestanas),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final (i, opcion) in opciones.indexed)
            Semantics(
              selected: opcion.valor == elegido,
              button: true,
              child: Container(
                key: Key('${prefijoClave}_$i'),
                decoration: BoxDecoration(
                  color: opcion.valor == elegido ? esquema.surface : null,
                  borderRadius: BorderRadius.circular(FormaGip.radioPestana),
                  boxShadow: opcion.valor == elegido
                      ? FormaGip.sombraPestana
                      : null,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(FormaGip.radioPestana),
                    canRequestFocus: false,
                    onTap: () => onElegir(opcion.valor),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            opcion.etiqueta,
                            style: tema.textTheme.labelLarge?.copyWith(
                              fontSize: 14,
                              fontWeight: opcion.valor == elegido
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: opcion.valor == elegido
                                  ? esquema.onSurface
                                  : esquema.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pildoras(BuildContext context) {
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
                canRequestFocus: false,
                onTap: () => onElegir(opcion.valor),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        opcion.etiqueta,
                        style: tema.textTheme.labelLarge?.copyWith(
                          fontSize: 13,
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
