import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/logo_gip.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';

/// Pantalla de una sección que se abre desde el menú lateral. Cada sección
/// declara las suyas en `<seccion>/rutas_<seccion>.dart`; solo se listan las
/// que ya tienen pantalla.
typedef Subseccion = ({String etiqueta, String ruta});

/// Sección de la navegación principal. [icono] recibe el tamaño (20 px en el
/// menú, 22 en la barra inferior) y toma el color del `IconTheme`.
typedef SeccionNavegacion = ({
  String etiqueta,
  Widget Function(double tamano) icono,
  List<Subseccion> subsecciones,
});

/// Menú lateral de la web (rediseño): la tienda arriba (logo, nombre y
/// dirección), las secciones con ícono, las subsecciones de la sección activa
/// y, al final, el usuario de la sesión (iniciales, nombre y rol).
class MenuLateral extends StatelessWidget {
  const MenuLateral({
    super.key,
    required this.secciones,
    required this.indiceActivo,
    required this.rutaActual,
    required this.onSeccion,
    required this.onSubseccion,
    required this.tienda,
    required this.direccion,
    required this.usuario,
    required this.rol,
  });

  static const ancho = 264.0;

  final List<SeccionNavegacion> secciones;
  final int indiceActivo;

  /// Ruta abierta: marca la subsección activa.
  final String rutaActual;
  final ValueChanged<int> onSeccion;
  final ValueChanged<Subseccion> onSubseccion;
  final String tienda;
  final String direccion;
  final String usuario;
  final String rol;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final esquema = tema.colorScheme;
    final contenido = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 22),
        child: Row(
          children: [
            const LogoGip.sigla(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tienda,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      color: esquema.onPrimary,
                    ),
                  ),
                  Text(
                    direccion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: extra.navTextoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      for (var i = 0; i < secciones.length; i++) ...[
        _ItemSeccion(
          seccion: secciones[i],
          activa: i == indiceActivo,
          onTap: () => onSeccion(i),
        ),
        if (i == indiceActivo && secciones[i].subsecciones.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 4, 0, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final sub in secciones[i].subsecciones)
                  _ItemSubseccion(
                    etiqueta: sub.etiqueta,
                    activa:
                        rutaActual == sub.ruta ||
                        rutaActual.startsWith('${sub.ruta}/'),
                    onTap: () => onSubseccion(sub),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 6),
      ],
    ];

    return Material(
      color: extra.navFondo,
      child: SizedBox(
        width: ancho,
        child: SafeArea(
          right: false,
          child: LayoutBuilder(
            builder: (context, restricciones) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (restricciones.maxHeight - 48).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        container: true,
                        explicitChildNodes: true,
                        label: 'Secciones',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: contenido,
                        ),
                      ),
                      const Spacer(),
                      _Usuario(nombre: usuario, rol: rol),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemSeccion extends StatelessWidget {
  const _ItemSeccion({
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
    final extra = tema.extension<ColoresExtraGip>()!;
    final esquema = tema.colorScheme;
    final color = activa ? esquema.onPrimary : extra.navTexto;
    final bordes = BorderRadius.circular(12);
    return Semantics(
      selected: activa,
      button: true,
      child: Material(
        color: activa ? esquema.primary : Colors.transparent,
        borderRadius: bordes,
        child: InkWell(
          onTap: onTap,
          borderRadius: bordes,
          hoverColor: esquema.onPrimary.withValues(alpha: 0.06),
          child: SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconTheme.merge(
                    data: IconThemeData(color: color, size: 20),
                    child: seccion.icono(20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    seccion.etiqueta,
                    style: tema.textTheme.bodyLarge?.copyWith(
                      color: color,
                      fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
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

class _ItemSubseccion extends StatelessWidget {
  const _ItemSubseccion({
    required this.etiqueta,
    required this.activa,
    required this.onTap,
  });

  final String etiqueta;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final blanco = tema.colorScheme.onPrimary;
    final bordes = BorderRadius.circular(10);
    return Semantics(
      selected: activa,
      button: true,
      child: Material(
        color: activa ? blanco.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: bordes,
        child: InkWell(
          onTap: onTap,
          borderRadius: bordes,
          hoverColor: blanco.withValues(alpha: 0.06),
          child: Container(
            // 38 px como el prototipo; el área táctil llega a 44 con la
            // separación entre filas.
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              etiqueta,
              style: tema.textTheme.labelMedium?.copyWith(
                color: activa ? blanco : extra.navTexto,
                fontWeight: activa ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Usuario de la sesión: iniciales, nombre y rol.
class _Usuario extends StatelessWidget {
  const _Usuario({required this.nombre, required this.rol});

  final String nombre;
  final String rol;

  /// Iniciales de las dos primeras palabras del nombre ("Carmen Ruiz" → "CR").
  static String iniciales(String nombre) => nombre
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p.characters.first.toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final esquema = tema.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: esquema.onPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: esquema.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Text(
                iniciales(nombre),
                style: tema.textTheme.labelMedium?.copyWith(
                  color: esquema.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.labelMedium?.copyWith(
                    color: esquema.onPrimary,
                  ),
                ),
                Text(
                  rol,
                  style: tema.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: extra.navTextoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
