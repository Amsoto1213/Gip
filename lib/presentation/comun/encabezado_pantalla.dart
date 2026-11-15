import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Encabezado de pantalla del rediseño: título en Archivo 800 (34 px web,
/// 30 px móvil, interletrado −0,02 em) con una línea de [contexto] en
/// `textoSecundario` y, si hay, una [accion] a la derecha.
///
/// En una pantalla interna ([onVolver] no nulo) la web muestra la miga
/// "[seccion] › [miga]" y el móvil el botón de volver con el título de 23 px.
class EncabezadoPantalla extends StatelessWidget {
  const EncabezadoPantalla({
    super.key,
    required this.titulo,
    this.contexto,
    this.seccion,
    this.miga,
    this.onVolver,
    this.accion,
  });

  final String titulo;
  final String? contexto;

  /// Sección a la que se vuelve ("Surtido").
  final String? seccion;

  /// Nombre corto de esta pantalla en la miga ("Pérdida o devolución"). Si
  /// es nulo se usa el [titulo].
  final String? miga;
  final VoidCallback? onVolver;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final web = FormaGip.esWeb(context);
    final onVolver = this.onVolver;
    final seccion = this.seccion;
    final contexto = this.contexto;
    final interna = onVolver != null;
    final tamanoTitulo = web ? 34.0 : (interna ? 23.0 : 30.0);
    final estiloTitulo = tema.textTheme.headlineLarge?.copyWith(
      fontSize: tamanoTitulo,
      letterSpacing: tamanoTitulo * -0.02,
    );
    final estiloContexto = tema.textTheme.bodyMedium?.copyWith(
      fontSize: web ? 16 : 13,
      color: esquema.onSurfaceVariant,
    );
    final titulo = Semantics(
      header: true,
      child: Text(this.titulo, style: estiloTitulo),
    );
    final textoContexto = contexto == null
        ? null
        : Text(contexto, style: estiloContexto);

    final Widget bloque;
    if (web) {
      bloque = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (interna && seccion != null) ...[
            _Miga(
              seccion: seccion,
              actual: miga ?? this.titulo,
              onVolver: onVolver,
            ),
            const SizedBox(height: 10),
          ],
          titulo,
          if (textoContexto != null) ...[
            const SizedBox(height: 6),
            textoContexto,
          ],
        ],
      );
    } else if (interna) {
      bloque = Row(
        children: [
          IconButton(
            onPressed: onVolver,
            tooltip: 'Volver',
            iconSize: 28,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (seccion != null)
                  Text(
                    seccion.toUpperCase(),
                    style: tema.textTheme.labelMedium?.copyWith(
                      color: esquema.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                titulo,
              ],
            ),
          ),
        ],
      );
    } else {
      // Móvil: la línea de contexto va encima del título (surtido-movil).
      bloque = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (textoContexto != null) ...[
            textoContexto,
            const SizedBox(height: 2),
          ],
          titulo,
        ],
      );
    }

    final accion = this.accion;
    if (accion == null) return bloque;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: bloque),
        const SizedBox(width: 16),
        accion,
      ],
    );
  }
}

/// "Surtido › Pérdida o devolución": tocar la sección vuelve.
class _Miga extends StatelessWidget {
  const _Miga({
    required this.seccion,
    required this.actual,
    required this.onVolver,
  });

  final String seccion;
  final String actual;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final estilo = tema.textTheme.labelMedium;
    return Row(
      children: [
        Tooltip(
          message: 'Volver a $seccion',
          child: InkWell(
            onTap: onVolver,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Align(
                  widthFactor: 1,
                  child: Text(
                    seccion,
                    style: estilo?.copyWith(color: esquema.primary),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, size: 16, color: esquema.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            actual,
            overflow: TextOverflow.ellipsis,
            style: estilo?.copyWith(
              fontWeight: FontWeight.w400,
              color: esquema.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
