import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Campo grande de búsqueda (58 px en la web, 52 en el móvil) con la lupa a
/// la izquierda y, si hay [onLeerCodigo], el botón oscuro del lector al lado.
/// Mientras no exista CUS-17 las pantallas no pasan [onLeerCodigo] y el botón
/// no se muestra.
///
/// Tiene dos usos:
/// - **Botón** (sin [controlador]): muestra la [pista] y al tocarlo llama a
///   [onTap] (Surtido y Vender abren Buscar producto).
/// - **Campo** (con [controlador]): se escribe ahí mismo (Buscar producto).
class BarraBusqueda extends StatefulWidget {
  const BarraBusqueda({
    super.key,
    required this.pista,
    this.onTap,
    this.controlador,
    this.campoKey,
    this.autofocus = false,
    this.sufijo,
    this.onChanged,
    this.onSubmitted,
    this.onLeerCodigo,
  }) : assert(
         (onTap == null) != (controlador == null),
         'Pase onTap (botón) o controlador (campo), no los dos',
       );

  final String pista;
  final VoidCallback? onTap;
  final TextEditingController? controlador;
  final Key? campoKey;
  final bool autofocus;

  /// Widget al final del campo (p. ej. el botón de borrar).
  final Widget? sufijo;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onLeerCodigo;

  @override
  State<BarraBusqueda> createState() => _BarraBusquedaState();
}

class _BarraBusquedaState extends State<BarraBusqueda> {
  bool _enfocado = false;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final web = FormaGip.esWeb(context);
    final alto = web ? 58.0 : 52.0;
    final bordes = BorderRadius.circular(FormaGip.radioBotonPrimario);
    final lupa = Icon(
      Icons.search,
      size: web ? 22 : 20,
      color: esquema.onSurfaceVariant,
    );
    final controlador = widget.controlador;

    final Widget contenido = controlador == null
        ? Semantics(
            button: true,
            label: widget.pista,
            excludeSemantics: true,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: bordes,
              child: Row(
                children: [
                  SizedBox(width: web ? 18 : 14),
                  lupa,
                  SizedBox(width: web ? 12 : 10),
                  Expanded(
                    child: Text(
                      widget.pista,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.bodyLarge?.copyWith(
                        color: esquema.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          )
        : Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onFocusChange: (enfocado) => setState(() => _enfocado = enfocado),
            child: Row(
              children: [
                SizedBox(width: web ? 18 : 14),
                lupa,
                Expanded(
                  child: TextField(
                    key: widget.campoKey,
                    controller: controlador,
                    autofocus: widget.autofocus,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    textInputAction: TextInputAction.search,
                    style: tema.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: widget.pista,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: web ? 12 : 10,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
                ?widget.sufijo,
                const SizedBox(width: 6),
              ],
            ),
          );

    final caja = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: alto,
      decoration: BoxDecoration(
        color: esquema.surface,
        borderRadius: bordes,
        border: Border.all(
          color: _enfocado ? esquema.primary : esquema.outline,
          width: FormaGip.grosorBordeCampo,
        ),
        boxShadow: _enfocado
            ? FormaGip.haloFoco
            : [FormaGip.sombraTarjeta.first],
      ),
      child: Material(type: MaterialType.transparency, child: contenido),
    );

    final onLeerCodigo = widget.onLeerCodigo;
    if (onLeerCodigo == null) return caja;
    final extra = tema.extension<ColoresExtraGip>()!;
    return Row(
      children: [
        Expanded(child: caja),
        SizedBox(width: web ? 12 : 10),
        IconButton(
          onPressed: onLeerCodigo,
          tooltip: 'Leer código con el lector',
          style: IconButton.styleFrom(
            backgroundColor: extra.navFondo,
            foregroundColor: esquema.onPrimary,
            fixedSize: Size.square(alto),
            shape: RoundedRectangleBorder(borderRadius: bordes),
          ),
          icon: Icon(Icons.qr_code_scanner, size: web ? 24 : 22),
        ),
      ],
    );
  }
}
