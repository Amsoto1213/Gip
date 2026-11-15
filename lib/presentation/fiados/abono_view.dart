import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/fiados/abono_view_model.dart';
import 'package:gip/presentation/fiados/fiados_view_model.dart';
import 'package:gip/presentation/fiados/widgets_fiados.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Registrar abono (CUS-08, mockup `mAbono`): a cuál fiado abona,
/// cuánto, con qué medio, y el botón fijo "Registrar abono de $ N". Termina
/// con verdadero si el abono quedó guardado. Si el guardado falla, el
/// formulario se cierra, el cliente se vuelve a leer de la base y su pantalla
/// muestra el error (DI-27).
class AbonoView extends StatefulWidget {
  const AbonoView({super.key});

  @override
  State<AbonoView> createState() => _AbonoViewState();
}

class _AbonoViewState extends State<AbonoView> {
  final _claveErrorFiado = GlobalKey();
  final _claveCampos = GlobalKey();
  final _claveError = GlobalKey();

  /// Lleva la vista al primer error: con la barra de abajo y el teclado puede
  /// quedar tapado en una pantalla de 5".
  void _mostrarPrimerError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AbonoViewModel>();
      final clave = vm.errorFiado != null
          ? _claveErrorFiado
          : vm.errorMonto != null
          ? _claveCampos
          : _claveError;
      final destino = clave.currentContext;
      if (destino != null) {
        Scrollable.ensureVisible(
          destino,
          duration: const Duration(milliseconds: 200),
          alignment: 0.1,
        );
      }
    });
  }

  Future<void> _registrar(BuildContext context) async {
    final abono = context.read<AbonoViewModel>();
    final fiados = context.read<FiadosViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    final navegador = GoRouter.of(context);
    FocusScope.of(context).unfocus();
    final registrado = await abono.registrar();
    if (registrado) {
      await fiados.recargar();
      mensajes.showSnackBar(
        SnackBar(
          content: Text(
            'Abono registrado. Nuevo saldo: ${pesos(abono.saldoNuevo!)}',
          ),
        ),
      );
      if (navegador.canPop()) navegador.pop(true);
    } else if (abono.debeRecargar) {
      fiados.avisar(abono.error!);
      await fiados.recargar();
      if (navegador.canPop()) navegador.pop(false);
    } else {
      _mostrarPrimerError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AbonoViewModel>();
    final tema = Theme.of(context);
    final nombre = context
        .read<FiadosViewModel>()
        .elegido
        ?.getNombre()
        .toUpperCase();
    final fiado = vm.fiado;
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                EncabezadoPantalla(
                  titulo: 'Registrar abono',
                  contexto: null,
                  seccion: nombre,
                  onVolver: () => context.pop(false),
                ),
                const SizedBox(height: 16),
                Text('¿A cuál fiado abona?', style: tema.textTheme.titleMedium),
                const SizedBox(height: 10),
                ListaFiadosParaAbono(vm: vm),
                if (vm.errorFiado case final e?) ...[
                  const SizedBox(height: 8),
                  Text(
                    e,
                    key: _claveErrorFiado,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                KeyedSubtree(
                  key: _claveCampos,
                  child: CamposAbono(vm: vm),
                ),
                if (vm.quedaSaldado && fiado != null) ...[
                  const SizedBox(height: 16),
                  AvisoSaldado(fiado: fiado),
                ],
                if (vm.error case final e?) ...[
                  const SizedBox(height: 12),
                  Text(
                    e,
                    key: _claveError,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BotonRegistrarAbono(vm: vm, onPressed: () => _registrar(context)),
              const SizedBox(height: 6),
              Text(
                'El efectivo entra a la caja de hoy; Nequi no mueve la caja.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
