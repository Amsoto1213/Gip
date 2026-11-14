import 'package:flutter/material.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:provider/provider.dart';

/// Pantalla de inicio de sesión con correo y contraseña (DI-05).
/// No hay mockup: usa los tokens del tema.
class IniciarSesionView extends StatefulWidget {
  const IniciarSesionView({super.key});

  @override
  State<IniciarSesionView> createState() => _IniciarSesionViewState();
}

class _IniciarSesionViewState extends State<IniciarSesionView> {
  final _correo = TextEditingController();
  final _clave = TextEditingController();

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  void _entrar() {
    context.read<IniciarSesionViewModel>().iniciarSesion(
      _correo.text,
      _clave.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IniciarSesionViewModel>();
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'GIP',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.displaySmall?.copyWith(
                        color: tema.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestor de Inventario Predictivo',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyLarge?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _correo,
                      enabled: !vm.enviando,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Correo'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _clave,
                      enabled: !vm.enviando,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _entrar(),
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                    ),
                    if (vm.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        vm.error!,
                        style: TextStyle(color: tema.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: vm.enviando ? null : _entrar,
                      child: vm.enviando
                          ? const SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : const Text('Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
