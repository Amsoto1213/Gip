import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/icono_paquete.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';

/// Logo del GIP: cuadro redondeado con el ícono de paquete. [sobreVerde]:
/// fondo blanco con el ícono en `primario` (panel del inicio de sesión);
/// si no, al revés. Con [LogoGip.sigla] lleva "GIP" en Archivo 800 en lugar
/// del ícono (menú lateral).
class LogoGip extends StatelessWidget {
  const LogoGip({super.key, this.tamano = 44, this.sobreVerde = false})
    : _sigla = false;

  const LogoGip.sigla({super.key, this.tamano = 44})
    : sobreVerde = false,
      _sigla = true;

  final double tamano;
  final bool sobreVerde;
  final bool _sigla;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final fondo = sobreVerde ? esquema.surface : esquema.primary;
    final tinta = sobreVerde ? esquema.primary : esquema.onPrimary;
    // 104 → 32, 80 → 26, 44 → 14, como en los prototipos.
    final radio = tamano >= 100
        ? 32.0
        : tamano >= 80
        ? 26.0
        : FormaGip.radioCajaIconoPequena;
    return Semantics(
      label: 'GIP',
      image: true,
      excludeSemantics: true,
      child: Container(
        width: tamano,
        height: tamano,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(radio),
          boxShadow: sobreVerde ? FormaGip.sombraLogo : null,
        ),
        child: _sigla
            ? Text(
                'GIP',
                style: tema.textTheme.titleLarge?.copyWith(
                  fontSize: tamano * 0.36,
                  color: tinta,
                ),
              )
            : IconoPaquete(tamano: tamano * 0.54, color: tinta),
      ),
    );
  }
}
