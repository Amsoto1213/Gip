import 'package:flutter/material.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/barra_inferior.dart';
import 'package:gip/presentation/comun/icono_paquete.dart';
import 'package:gip/presentation/comun/menu_lateral.dart';
import 'package:gip/presentation/negocio/rutas_negocio.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Navegación principal con las 5 secciones (tokens.md): [BarraInferior] en
/// pantallas angostas y [MenuLateral] en anchas (RNF-19, RNF-20). El menú
/// toma la tienda y el usuario de la sesión.
class MarcoNavegacion extends StatelessWidget {
  const MarcoNavegacion({super.key, required this.shell});

  /// Desde este ancho se usa el menú lateral.
  static const anchoMenuLateral = 1024.0;

  final StatefulNavigationShell shell;

  static final List<SeccionNavegacion> secciones = [
    (
      etiqueta: 'Vender',
      icono: (t) => Icon(Icons.shopping_bag_outlined, size: t),
      subsecciones: const [],
    ),
    (
      etiqueta: 'Surtido',
      icono: (t) => IconoPaquete(tamano: t),
      subsecciones: subseccionesSurtido,
    ),
    (
      etiqueta: 'Fiados',
      icono: (t) => Icon(Icons.menu_book_outlined, size: t),
      subsecciones: const [],
    ),
    (
      etiqueta: 'Caja',
      icono: (t) => Icon(Icons.credit_card_outlined, size: t),
      subsecciones: const [],
    ),
    (
      etiqueta: 'Negocio',
      icono: (t) => Icon(Icons.show_chart, size: t),
      subsecciones: subseccionesNegocio,
    ),
  ];

  /// Rol como se muestra en el menú (DI-23).
  static String nombreRol(Usuario usuario) =>
      usuario is Administrador ? 'Administrador' : 'Empleado';

  /// Tocar la sección activa vuelve a su pantalla inicial.
  void _irA(int indice) =>
      shell.goBranch(indice, initialLocation: indice == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        if (restricciones.maxWidth < anchoMenuLateral) {
          return Scaffold(
            body: shell,
            bottomNavigationBar: BarraInferior(
              secciones: secciones,
              indiceActivo: shell.currentIndex,
              onSeccion: _irA,
            ),
          );
        }
        final sesion = context.watch<IniciarSesionViewModel>().usuarioActivo;
        return Scaffold(
          body: Row(
            children: [
              MenuLateral(
                secciones: secciones,
                indiceActivo: shell.currentIndex,
                rutaActual: GoRouterState.of(context).uri.path,
                onSeccion: _irA,
                onSubseccion: (sub) => context.go(sub.ruta),
                tienda: sesion?.tienda.getNombre() ?? '',
                direccion: sesion?.tienda.getDireccion() ?? '',
                usuario: sesion?.usuario.getNombre() ?? '',
                rol: sesion == null ? '' : nombreRol(sesion.usuario),
              ),
              Expanded(child: shell),
            ],
          ),
        );
      },
    );
  }
}
