import 'package:flutter/material.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Navegación principal con las 5 secciones (tokens.md): barra inferior en
/// pantallas angostas y barra lateral en anchas (RNF-19, RNF-20).
class MarcoNavegacion extends StatelessWidget {
  const MarcoNavegacion({super.key, required this.shell});

  /// Desde este ancho se usa la barra lateral.
  static const anchoBarraLateral = 600.0;

  /// Desde este ancho la barra lateral muestra los nombres al lado del ícono.
  static const anchoBarraExtendida = 1024.0;

  final StatefulNavigationShell shell;

  static const _secciones = [
    (etiqueta: 'Vender', icono: Icons.shopping_bag_outlined),
    (etiqueta: 'Surtido', icono: Icons.inventory_2_outlined),
    (etiqueta: 'Fiados', icono: Icons.menu_book_outlined),
    (etiqueta: 'Caja', icono: Icons.point_of_sale_outlined),
    (etiqueta: 'Negocio', icono: Icons.storefront_outlined),
  ];

  /// Tocar la sección activa vuelve a su pantalla inicial.
  void _irA(int indice) =>
      shell.goBranch(indice, initialLocation: indice == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        if (restricciones.maxWidth < anchoBarraLateral) {
          return Scaffold(
            body: shell,
            bottomNavigationBar: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: _irA,
                destinations: [
                  for (final s in _secciones)
                    NavigationDestination(
                      icon: Icon(s.icono),
                      label: s.etiqueta,
                    ),
                ],
              ),
            ),
          );
        }
        final extendida = restricciones.maxWidth >= anchoBarraExtendida;
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: extendida,
                minExtendedWidth: 240,
                labelType: extendida
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                leading: _MarcaGip(extendida: extendida),
                selectedIndex: shell.currentIndex,
                onDestinationSelected: _irA,
                destinations: [
                  for (final s in _secciones)
                    NavigationRailDestination(
                      icon: Icon(s.icono),
                      label: Text(s.etiqueta),
                    ),
                ],
              ),
              Expanded(child: shell),
            ],
          ),
        );
      },
    );
  }
}

/// Logo GIP y, con la barra extendida, el nombre de la tienda (mockup `Panel`).
class _MarcaGip extends StatelessWidget {
  const _MarcaGip({required this.extendida});

  final bool extendida;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tienda = context.select<IniciarSesionViewModel, String?>(
      (vm) => vm.usuarioActivo?.tienda.getNombre(),
    );
    final logo = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tema.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'GIP',
        style: tema.textTheme.labelLarge?.copyWith(
          color: tema.colorScheme.onPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: SizedBox(
        width: extendida ? 208 : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            logo,
            if (extendida && tienda != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tienda,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.titleSmall?.copyWith(
                    color: tema.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
