import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';

/// Contador de un número entero con "−" y "+" a los lados (copias de
/// etiquetas). Los botones se desactivan en [minimo] y [maximo], o todos si
/// [onCambio] es null. [etiquetaMenos] y [etiquetaMas] son sus nombres para el
/// lector de pantalla.
class ContadorEntero extends StatelessWidget {
  const ContadorEntero({
    super.key,
    required this.valor,
    required this.onCambio,
    this.minimo = 1,
    required this.maximo,
    this.etiquetaMenos = 'Una menos',
    this.etiquetaMas = 'Una más',
  });

  final int valor;
  final ValueChanged<int>? onCambio;
  final int minimo;
  final int maximo;
  final String etiquetaMenos;
  final String etiquetaMas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cambio = onCambio;
    return Row(
      children: [
        BotonIconoSecundario(
          key: const Key('contador_menos'),
          icono: Icons.remove,
          tooltip: etiquetaMenos,
          onPressed: cambio == null || valor <= minimo
              ? null
              : () => cambio(valor - 1),
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              '$valor',
              key: const Key('contador_valor'),
              textAlign: TextAlign.center,
              style: tema.textTheme.headlineSmall?.cifrasTabulares,
            ),
          ),
        ),
        BotonIconoSecundario(
          key: const Key('contador_mas'),
          icono: Icons.add,
          tooltip: etiquetaMas,
          onPressed: cambio == null || valor >= maximo
              ? null
              : () => cambio(valor + 1),
        ),
      ],
    );
  }
}
