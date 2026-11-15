import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Acción de una sección como tarjeta: caja de ícono `primarioSuave` con el
/// [icono] en `primario`, [titulo] 17 px peso 700 y una línea de
/// [descripcion]. Con [vertical] (móvil) va el ícono arriba y el título
/// abajo, sin la descripción visible. Con el mouse encima, borde `primario`.
class TarjetaAccion extends StatefulWidget {
  const TarjetaAccion({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
    this.vertical = false,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;
  final bool vertical;

  @override
  State<TarjetaAccion> createState() => _TarjetaAccionState();
}

class _TarjetaAccionState extends State<TarjetaAccion> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final vertical = widget.vertical;
    final radio = vertical ? 18.0 : FormaGip.radioTarjetaAccion;
    final bordes = BorderRadius.circular(radio);
    final cajaIcono = Container(
      width: vertical ? 40 : 52,
      height: vertical ? 40 : 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: esquema.primaryContainer,
        borderRadius: BorderRadius.circular(
          vertical ? 12 : FormaGip.radioCajaIcono,
        ),
      ),
      child: Icon(
        widget.icono,
        size: vertical ? 20 : 24,
        color: esquema.primary,
      ),
    );
    final contenido = vertical
        ? SizedBox(
            height: 90, // 92 con el borde (prototipo).
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                cajaIcono,
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    widget.titulo,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                cajaIcono,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titulo,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(widget.descripcion, style: tema.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          );
    return Semantics(
      button: true,
      label: vertical ? '${widget.titulo}. ${widget.descripcion}' : null,
      excludeSemantics: vertical,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: esquema.surface,
          borderRadius: bordes,
          border: Border.all(
            color: _encima ? esquema.primary : esquema.outlineVariant,
          ),
          boxShadow: _encima
              ? FormaGip.sombraTarjetaActiva
              : FormaGip.sombraTarjeta,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (encima) => setState(() => _encima = encima),
            borderRadius: bordes,
            child: contenido,
          ),
        ),
      ),
    );
  }
}
