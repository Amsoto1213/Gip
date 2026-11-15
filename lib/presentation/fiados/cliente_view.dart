import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/fiados/fiados_view_model.dart';
import 'package:gip/presentation/fiados/rutas_fiados.dart';
import 'package:gip/presentation/fiados/widgets_fiados.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla del cliente (CUS-19 mínimo, mockup `Cliente`): teléfono, lo que
/// debe en total, "Registrar abono" y sus fiados pendientes. El historial
/// completo, "Cliente desde…" y "Eliminar datos del cliente" llegan con
/// CUS-19 completo y CUS-21 (DI-27).
class ClienteView extends StatelessWidget {
  const ClienteView({super.key});

  void _volver(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(rutaPrincipalFiados);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FiadosViewModel>();
    final cliente = vm.elegido;
    if (cliente == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: EncabezadoPantalla(
              titulo: 'Cliente',
              seccion: 'Fiados',
              onVolver: () => _volver(context),
            ),
          ),
        ),
      );
    }
    final saldo = vm.saldoDe(cliente);
    final debe = saldo > Decimal.zero;
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
                  titulo: cliente.getNombre(),
                  seccion: 'Fiados',
                  onVolver: () => _volver(context),
                ),
                const SizedBox(height: 16),
                if (vm.aviso case final aviso?) ...[
                  TarjetaAviso(key: const Key('cliente_aviso'), titulo: aviso),
                  const SizedBox(height: 16),
                ],
                ResumenCliente(
                  cliente: cliente,
                  saldoTotal: saldo,
                  accion: debe
                      ? BotonPrimario(
                          key: const Key('cliente_abonar'),
                          texto: 'Registrar abono',
                          icono: Icons.payments_outlined,
                          onPressed: () => abrirAbono(context, vm),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
