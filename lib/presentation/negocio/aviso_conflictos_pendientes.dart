import 'package:flutter/material.dart';
import 'package:gip/business/workflow/info_tienda/revisar_conflictos_coordinator.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/datos_actualizados.dart';
import 'package:gip/presentation/comun/nota_info.dart';
import 'package:gip/presentation/negocio/conflictos_pendientes_view_model.dart';
import 'package:gip/presentation/negocio/rutas_negocio.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Aviso para el propietario de que hay conflictos de sincronización por
/// revisar, con el botón que lleva a Revisar sincronización (CUS-22, DI-50).
/// Explica por qué la existencia puede cambiar: hasta que el propietario
/// decide, cuenta todo lo registrado (por ejemplo las dos entradas de un posible
/// duplicado) y baja si anula alguna.
///
/// Se cuenta al abrirse, cada vez que la pestaña vuelve a verse, al volver de
/// Revisar sincronización y cuando llegan datos de otros equipos
/// ([DatosActualizados]). No sale si no hay conflictos, si quien lo ve no es el
/// propietario o si el aviso se prueba sin los coordinadores en el árbol.
class AvisoConflictosPendientes extends StatefulWidget {
  const AvisoConflictosPendientes({super.key});

  static String titulo(int total) => total == 1
      ? 'Hay 1 conflicto por revisar.'
      : 'Hay $total conflictos por revisar.';

  static const detalle =
      'Mientras tanto la existencia cuenta todo lo registrado y puede bajar '
      'cuando usted lo resuelva.';

  @override
  State<AvisoConflictosPendientes> createState() =>
      _AvisoConflictosPendientesState();
}

class _AvisoConflictosPendientesState extends State<AvisoConflictosPendientes> {
  ConflictosPendientesViewModel? _vm;
  DatosActualizados? _datos;
  bool? _visible;

  @override
  void initState() {
    super.initState();
    try {
      final activo = context.read<IniciarSesionViewModel>().usuarioActivo;
      if (activo != null) {
        _vm = ConflictosPendientesViewModel(
          context.read<RevisarConflictosCoordinator>(),
          activo,
        )..cargar();
      }
    } on ProviderNotFoundException {
      _vm = null;
    }
    try {
      _datos = context.read<DatosActualizados>()..addListener(_recargar);
    } on ProviderNotFoundException {
      _datos = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // La pestaña inactiva queda con TickerMode apagado (StatefulShellRoute).
    final visible = TickerMode.valuesOf(context).enabled;
    if (_visible == false && visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recargar());
    }
    _visible = visible;
  }

  void _recargar() {
    if (mounted) _vm?.cargar();
  }

  Future<void> _revisar() async {
    await context.push<void>(rutaConflictos);
    _recargar();
  }

  @override
  void dispose() {
    _datos?.removeListener(_recargar);
    _vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.total == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            key: const Key('aviso_conflictos'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NotaInfo(
                destacado: AvisoConflictosPendientes.titulo(vm.total),
                texto: AvisoConflictosPendientes.detalle,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: BotonSecundario(
                  key: const Key('aviso_conflictos_revisar'),
                  texto: 'Revisar',
                  alto: 44,
                  onPressed: _revisar,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
