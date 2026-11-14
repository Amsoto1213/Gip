import 'package:flutter/material.dart';

/// Se muestra mientras se revisa si el dispositivo guarda una sesión.
class VerificandoSesionView extends StatelessWidget {
  const VerificandoSesionView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
