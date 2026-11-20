import 'package:flutter/material.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/casilla_registro.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/mensaje_resultado.dart';
import 'package:gip/presentation/comun/nota_info.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/negocio/conflictos_view_model.dart';
import 'package:gip/presentation/negocio/rutas_negocio.dart';
import 'package:gip/presentation/surtido/formato_movimiento.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Revisar sincronización (CUS-22), según los mockups `mConflictos`
/// y `wConflictos` con los componentes del rediseño: una tarjeta por conflicto
/// pendiente, con lo que pasó, los registros que el propietario puede marcar y
/// los botones para decidir. El sistema no adivina: espera la decisión.
///
/// No se muestran los nombres de los equipos ("Celular de Luis", "Caja del
/// mostrador"): la entrada del registro no guarda de qué equipo viene. Cada
/// registro se identifica por su etiqueta (DI-45).
class ConflictosView extends StatefulWidget {
  const ConflictosView({super.key});

  static const textoContexto =
      'Al unir lo registrado sin internet en los equipos, esto no cuadró. '
      'Usted decide; el sistema no adivina.';

  static const textoSinConflictos =
      'No hay nada por revisar. Lo registrado en todos los equipos cuadra.';

  /// Nombre del tipo, en el lenguaje del tendero.
  static String nombreTipo(TipoConflicto tipo) => switch (tipo) {
    TipoConflicto.posibleDuplicado => 'Posible registro repetido',
    TipoConflicto.stockNegativo => 'Existencia negativa',
    TipoConflicto.abonoExcedeSaldo => 'Abono mayor que el saldo',
    TipoConflicto.codigoRepetido => 'Código repetido',
    TipoConflicto.movimientoCajaCerrada => 'Movimiento en caja cerrada',
  };

  /// Cómo decidir, debajo de la descripción.
  static String ayudaTipo(TipoConflicto tipo) => switch (tipo) {
    TipoConflicto.posibleDuplicado =>
      'Marque los registros que sí ocurrieron. Los que deje sin marcar se '
          'anulan.',
    TipoConflicto.stockNegativo =>
      'Cuente el producto para corregir la existencia, o acepte lo que hay.',
    TipoConflicto.abonoExcedeSaldo =>
      'Marque los abonos que se anulan. El dinero se devuelve en caja; lo '
          'pagado por Nequi se devuelve fuera del sistema.',
    TipoConflicto.codigoRepetido => 'Marque el producto que pierde el código.',
    TipoConflicto.movimientoCajaCerrada =>
      'Se acepta el movimiento y se recalcula la diferencia del cierre.',
  };

  @override
  State<ConflictosView> createState() => _ConflictosViewState();
}

class _ConflictosViewState extends State<ConflictosView> {
  /// Para llevar la pantalla hasta el resultado de un intento.
  final _resultadoKey = GlobalKey();

  void _volver() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(rutaPrincipalNegocio);
    }
  }

  void _verResultado() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contexto = _resultadoKey.currentContext;
      if (!mounted || contexto == null) return;
      Scrollable.ensureVisible(
        contexto,
        alignment: 0.2,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _decidir(Future<void> Function() accion) async {
    await accion();
    if (mounted) _verResultado();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ConflictosViewModel>();
    final web = FormaGip.esWeb(context);

    final List<Widget> cuerpo;
    if (vm.errorCarga case final error?) {
      cuerpo = [
        TarjetaAviso(
          key: const Key('conflictos_error_carga'),
          titulo: error,
          icono: error == ConflictosViewModel.mensajeSoloPropietario
              ? Icons.lock_outline
              : Icons.warning_amber_rounded,
        ),
      ];
    } else if (vm.cargando && vm.conflictos.isEmpty) {
      cuerpo = const [
        Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    } else {
      cuerpo = [
        _Resultado(key: _resultadoKey, vm: vm),
        if (vm.conflictos.isEmpty)
          const NotaInfo(
            key: Key('conflictos_vacio'),
            texto: ConflictosView.textoSinConflictos,
          )
        else
          for (final (i, c) in vm.conflictos.indexed) ...[
            if (i > 0) const SizedBox(height: 16),
            _TarjetaConflicto(
              vm: vm,
              conflicto: c,
              web: web,
              onDecidir: _decidir,
            ),
          ],
      ];
    }

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: web ? 1240 : 880),
            child: RefreshIndicator(
              onRefresh: vm.cargar,
              child: ListView(
                padding: web
                    ? const EdgeInsets.fromLTRB(44, 32, 44, 48)
                    : const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  EncabezadoPantalla(
                    titulo: 'Revisar sincronización',
                    miga: 'Revisar sincronización',
                    seccion: 'Negocio',
                    contexto: ConflictosView.textoContexto,
                    onVolver: _volver,
                  ),
                  SizedBox(height: web ? 24 : 16),
                  ...cuerpo,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lo que dejó el último intento de resolver.
class _Resultado extends StatelessWidget {
  const _Resultado({super.key, required this.vm});

  final ConflictosViewModel vm;

  @override
  Widget build(BuildContext context) {
    final Widget? tarjeta;
    if (vm.error case final error?) {
      tarjeta = TarjetaAviso(
        key: const Key('conflictos_error'),
        titulo: error,
        icono: error == ConflictosViewModel.mensajeSoloPropietario
            ? Icons.lock_outline
            : Icons.warning_amber_rounded,
      );
    } else if (vm.mensajeListo case final listo?) {
      tarjeta = MensajeResultado(
        key: const Key('conflictos_listo'),
        texto: listo,
        esError: false,
      );
    } else {
      tarjeta = null;
    }
    if (tarjeta == null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: tarjeta);
  }
}

class _TarjetaConflicto extends StatelessWidget {
  const _TarjetaConflicto({
    required this.vm,
    required this.conflicto,
    required this.web,
    required this.onDecidir,
  });

  final ConflictosViewModel vm;
  final ConflictoSincronizacion conflicto;
  final bool web;
  final Future<void> Function(Future<void> Function()) onDecidir;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final c = conflicto;
    final registros = vm.registrosElegibles(c);
    final id = c.getId();
    return TarjetaGip(
      key: Key('conflicto_$id'),
      padding: EdgeInsets.all(web ? 24 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PildoraEstado(
                ConflictosView.nombreTipo(c.getTipo()),
                tono: TonoEstado.informativo,
              ),
              Text(
                'Detectado ${cuandoMovimiento(c.getFecha(), DateTime.now()).toLowerCase()}',
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(vm.descripcionDe(c), style: tema.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            ConflictosView.ayudaTipo(c.getTipo()),
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
          if (registros.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final r in registros) ...[
              CasillaRegistro(
                key: Key('registro_${r.id}'),
                titulo: r.etiqueta,
                marcada: vm.estaMarcado(c, r.id),
                onCambio: vm.ocupado ? null : (m) => vm.marcar(c, r.id, m),
              ),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 6),
          _Botones(vm: vm, conflicto: c, web: web, onDecidir: onDecidir),
        ],
      ),
    );
  }
}

/// Los botones según el tipo; el principal va en verde y el resto de
/// contorno.
class _Botones extends StatelessWidget {
  const _Botones({
    required this.vm,
    required this.conflicto,
    required this.web,
    required this.onDecidir,
  });

  final ConflictosViewModel vm;
  final ConflictoSincronizacion conflicto;
  final bool web;
  final Future<void> Function(Future<void> Function()) onDecidir;

  @override
  Widget build(BuildContext context) {
    final c = conflicto;
    final id = c.getId();
    final libre = vm.ocupado ? null : () {};

    Widget primario(String texto, String clave, VoidCallback? accion) =>
        BotonPrimario(
          key: Key('${clave}_$id'),
          texto: texto,
          onPressed: accion,
        );
    Widget secundario(
      String texto,
      String clave,
      VoidCallback? accion, {
      IconData? icono,
    }) => BotonSecundario(
      key: Key('${clave}_$id'),
      texto: texto,
      icono: icono,
      onPressed: accion,
      expandido: !web,
    );

    VoidCallback? decidir(Future<void> Function() accion) =>
        libre == null ? null : () => onDecidir(accion);

    final guardar = vm.puedeGuardarDecision(c)
        ? () => onDecidir(() => vm.guardarDecision(c))
        : null;

    final botones = switch (c.getTipo()) {
      TipoConflicto.posibleDuplicado => [
        primario('Guardar decisión', 'conflicto_guardar', guardar),
        secundario(
          'Son registros distintos',
          'conflicto_distintos',
          decidir(() => vm.resolverSinElegir(c)),
        ),
      ],
      TipoConflicto.stockNegativo => [
        secundario(
          'Aceptar así',
          'conflicto_aceptar',
          decidir(() => vm.resolverSinElegir(c)),
        ),
        // Ir al conteo no cierra el conflicto: se cierra al aceptar o cuando
        // el conteo deja la existencia en orden (DI-45).
        secundario(
          'Ir al conteo',
          'conflicto_conteo',
          libre == null ? null : () => context.push(rutaConteo),
          icono: Icons.fact_check_outlined,
        ),
      ],
      TipoConflicto.abonoExcedeSaldo => [
        primario('Anular abonos marcados', 'conflicto_guardar', guardar),
      ],
      TipoConflicto.codigoRepetido => [
        primario('Quitar el código', 'conflicto_guardar', guardar),
      ],
      TipoConflicto.movimientoCajaCerrada => [
        primario(
          'Aceptar y recalcular',
          'conflicto_aceptar',
          decidir(() => vm.resolverSinElegir(c)),
        ),
      ],
    };

    if (web) {
      return Wrap(spacing: 12, runSpacing: 12, children: botones);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, b) in botones.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          b,
        ],
      ],
    );
  }
}
