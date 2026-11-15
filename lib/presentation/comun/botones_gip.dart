import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/comun/tema/tipografia_gip.dart';

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
    this.valor,
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

  /// Monto a la derecha, con cifras tabulares y una flecha ("Cobrar …
  /// $ 5.600 ›"). Con valor, el texto va a la izquierda.
  final String? valor;

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
        child: valor != null
            ? Row(
                children: [
                  if (marca != null) ...[marca, const SizedBox(width: 10)],
                  Expanded(child: etiqueta),
                  const SizedBox(width: 12),
                  Text(
                    valor!,
                    style: tema.textTheme.headlineMedium
                        ?.copyWith(
                          fontSize: 20,
                          color: activo ? colorTexto : null,
                        )
                        .cifrasTabulares,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right),
                ],
              )
            : Row(
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

/// Botón principal cuadrado con solo un ícono (48 px, radio 16, sombra
/// `botonPrimario`): la acción del encabezado en el móvil ("Producto nuevo").
/// El [tooltip] es también su nombre para el lector de pantalla.
class BotonIconoPrimario extends StatelessWidget {
  const BotonIconoPrimario({
    super.key,
    required this.icono,
    required this.tooltip,
    required this.onPressed,
    this.tamano = 48,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback? onPressed;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final bordes = BorderRadius.circular(FormaGip.radioBotonPrimario);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: bordes,
        boxShadow: onPressed == null ? null : FormaGip.sombraBotonPrimario,
      ),
      child: IconButton.filled(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          fixedSize: Size.square(tamano),
          shape: RoundedRectangleBorder(borderRadius: bordes),
          backgroundColor: esquema.primary,
          foregroundColor: esquema.onPrimary,
        ),
        icon: Icon(icono, size: 22),
      ),
    );
  }
}

/// Botón secundario cuadrado con solo un ícono (48 px, contorno `outline`,
/// fondo blanco): "día anterior" y "día siguiente" del Reporte del día. El
/// [tooltip] es también su nombre para el lector de pantalla.
class BotonIconoSecundario extends StatelessWidget {
  const BotonIconoSecundario({
    super.key,
    required this.icono,
    required this.tooltip,
    required this.onPressed,
    this.tamano = 48,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback? onPressed;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return IconButton.outlined(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        fixedSize: Size.square(tamano),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FormaGip.radioCampo),
        ),
        backgroundColor: esquema.surface,
        foregroundColor: esquema.primary,
        side: BorderSide(
          color: onPressed == null ? esquema.outlineVariant : esquema.outline,
          width: FormaGip.grosorBordeCampo,
        ),
      ),
      icon: Icon(icono, size: 22),
    );
  }
}
