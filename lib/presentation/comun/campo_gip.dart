import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Campo del rediseño: etiqueta arriba (14 px, peso 600), caja de 52–54 px con
/// radio 14, borde 1,5 px `bordeFuerte` e [icono] a la izquierda en
/// `textoSecundario`. Con foco: borde `primario` y halo de 4 px. Con
/// [contrasena] oculta el texto y agrega el botón de ojo.
///
/// [campoKey] va en el `TextField` para que las pruebas lo encuentren.
class CampoGip extends StatefulWidget {
  const CampoGip({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.campoKey,
    this.icono,
    this.pista,
    this.ayuda,
    this.error,
    this.prefijo,
    this.contrasena = false,
    this.habilitado = true,
    this.alto = 54,
    this.tipoTeclado,
    this.accionTeclado,
    this.autofillHints,
    this.formateadores,
    this.mayusculas = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
  });

  /// Texto encima del campo. Vacío para un campo sin etiqueta.
  final String etiqueta;
  final TextEditingController controlador;
  final Key? campoKey;
  final IconData? icono;

  /// Texto gris dentro del campo vacío ("nombre@tienda.com").
  final String? pista;

  /// Línea gris debajo del campo ("El código interno no se cambia").
  final String? ayuda;

  /// Mensaje de error del valor escrito; pinta el borde en `error`.
  final String? error;

  /// Texto fijo antes del valor ("$ ").
  final String? prefijo;
  final bool contrasena;
  final bool habilitado;

  /// 54 px en la web, 52 en el móvil.
  final double alto;
  final TextInputType? tipoTeclado;
  final TextInputAction? accionTeclado;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? formateadores;
  final TextCapitalization mayusculas;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<CampoGip> createState() => _CampoGipState();
}

class _CampoGipState extends State<CampoGip> {
  bool _enfocado = false;
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final icono = widget.icono;
    final campo = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (enfocado) => setState(() => _enfocado = enfocado),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FormaGip.radioCampo),
          boxShadow: _enfocado ? FormaGip.haloFoco : null,
        ),
        child: TextField(
          key: widget.campoKey,
          controller: widget.controlador,
          enabled: widget.habilitado,
          obscureText: widget.contrasena && _oculto,
          keyboardType: widget.tipoTeclado,
          textInputAction: widget.accionTeclado,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.formateadores,
          textCapitalization: widget.mayusculas,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: tema.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.pista,
            errorText: widget.error,
            errorMaxLines: 2,
            prefixText: widget.prefijo,
            constraints: BoxConstraints(minHeight: widget.alto),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: (widget.alto - 22) / 2,
            ),
            prefixIcon: icono == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(icono, size: 20),
                  ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
            prefixIconColor: esquema.onSurfaceVariant,
            suffixIcon: widget.contrasena
                ? Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton(
                      onPressed: () => setState(() => _oculto = !_oculto),
                      tooltip: _oculto
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      constraints: const BoxConstraints.tightFor(
                        width: 44,
                        height: 44,
                      ),
                      color: esquema.onSurfaceVariant,
                      icon: Icon(
                        _oculto
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
    final ayuda = widget.ayuda;
    if (widget.etiqueta.isEmpty && ayuda == null) return campo;
    // La etiqueta se lee justo antes del campo. No se usa MergeSemantics: con
    // prefijo de pesos o el botón de ojo, fundir los nodos rompe el árbol de
    // semántica.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.etiqueta.isNotEmpty) ...[
          Text(widget.etiqueta, style: tema.textTheme.labelMedium),
          const SizedBox(height: 8),
        ],
        campo,
        if (ayuda != null) ...[
          const SizedBox(height: 6),
          Text(ayuda, style: tema.textTheme.bodySmall?.copyWith(fontSize: 13)),
        ],
      ],
    );
  }
}
