import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Pide una confirmación explícita antes de una acción que no se puede
/// deshacer (RNF-26): un diálogo con la [pregunta], "Cancelar" y el botón de
/// [textoConfirmar] en rojo. Termina con verdadero solo si el tendero
/// confirma; tocar fuera, "Cancelar" o atrás es no confirmar.
Future<bool> pedirConfirmacion(
  BuildContext context, {
  required String pregunta,
  required String textoConfirmar,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    barrierColor: Theme.of(context).colorScheme.scrim,
    builder: (contexto) {
      final tema = Theme.of(contexto);
      return AlertDialog(
        key: const Key('dialogo_confirmacion'),
        backgroundColor: tema.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FormaGip.radioTarjeta),
        ),
        content: Text(pregunta, style: tema.textTheme.titleMedium),
        actionsOverflowButtonSpacing: 8,
        actions: [
          BotonSecundario(
            key: const Key('confirmacion_cancelar'),
            texto: 'Cancelar',
            sinBorde: true,
            onPressed: () => Navigator.of(contexto).pop(false),
          ),
          BotonDestructivo(
            key: const Key('confirmacion_confirmar'),
            texto: textoConfirmar,
            relleno: true,
            onPressed: () => Navigator.of(contexto).pop(true),
          ),
        ],
      );
    },
  );
  return confirmado ?? false;
}
