import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Botón principal del rediseño: verde `primario`, texto blanco 17 px peso
/// 700, radio 16, sombra `botonPrimario` y hover/presionado en
/// `primarioOscuro` (del tema). Con [cargando] muestra un indicador y no se
/// puede tocar. Sin [onPressed] queda deshabilitado y sin sombra.
class BotonPrimario extends StatelessWidget {
  const BotonPrimario({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icono,
    this.iconoAlFinal = false,
    this.cargando = false,
    this.compacto = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;

  /// El ícono va a la derecha del texto ("Entrar →").
  final bool iconoAlFinal;
  final bool cargando;

  /// 50 px de alto, radio 14 y texto 16: botones de encabezado
  /// ("Producto nuevo").
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final activo = onPressed != null && !cargando;
    final radio = compacto ? FormaGip.radioCampo : FormaGip.radioBotonPrimario;
    final alto = compacto ? 50.0 : FormaGip.altoBotonPrimario;
    final colorTexto = tema.colorScheme.onPrimary;
    final Widget? marca = cargando
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: tema.colorScheme.onSurfaceVariant,
            ),
          )
        : icono == null
        ? null
        : Icon(icono, size: 20);
    final etiqueta = Text(texto, overflow: TextOverflow.ellipsis);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radio),
        boxShadow: activo ? FormaGip.sombraBotonPrimario : null,
      ),
      child: FilledButton(
        onPressed: activo ? onPressed : null,
        style: FilledButton.styleFrom(
          minimumSize: Size(compacto ? 0 : double.infinity, alto),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          foregroundColor: colorTexto,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radio),
          ),
          textStyle: tema.textTheme.titleMedium?.copyWith(
            fontSize: compacto ? 16 : 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Row(
          mainAxisSize: compacto ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (marca != null && !iconoAlFinal) ...[
              marca,
              const SizedBox(width: 10),
            ],
            Flexible(child: etiqueta),
            if (marca != null && iconoAlFinal) ...[
              const SizedBox(width: 10),
              marca,
            ],
          ],
        ),
      ),
    );
  }
}

/// Botón secundario: contorno 1,5 px `bordeFuerte`, fondo blanco y texto verde
/// en negrita ("Cambiar producto", "Cerrar sesión"). Con [sinBorde] queda solo
/// el texto en `textoSecundario` ("Cancelar").
class BotonSecundario extends StatelessWidget {
  const BotonSecundario({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icono,
    this.alto = 48,
    this.sinBorde = false,
    this.expandido = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;

  /// Al menos 44 px (área táctil, RNF-19).
  final double alto;
  final bool sinBorde;

  /// Ocupa todo el ancho disponible.
  final bool expandido;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final color = sinBorde ? esquema.onSurfaceVariant : esquema.primary;
    final estilo = OutlinedButton.styleFrom(
      minimumSize: Size(expandido ? double.infinity : 44, alto),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      foregroundColor: color,
      backgroundColor: sinBorde ? Colors.transparent : esquema.surface,
      side: sinBorde
          ? BorderSide.none
          : BorderSide(
              color: esquema.outline,
              width: FormaGip.grosorBordeCampo,
            ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: tema.textTheme.labelLarge?.copyWith(
        fontSize: sinBorde ? 15 : 14,
        fontWeight: sinBorde ? FontWeight.w600 : FontWeight.w700,
      ),
    );
    final icono = this.icono;
    return icono == null
        ? OutlinedButton(
            onPressed: onPressed,
            style: estilo,
            child: Text(texto),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: estilo,
            icon: Icon(icono, size: 18),
            label: Text(texto),
          );
  }
}
