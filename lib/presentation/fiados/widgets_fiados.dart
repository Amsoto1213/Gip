import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/medio_pago.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/dialogo_confirmacion.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/opcion_radio.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/fiados/abono_view_model.dart';
import 'package:gip/presentation/fiados/fiados_view_model.dart';
import 'package:gip/presentation/fiados/formato_fecha.dart';

/// "$ 47.500".
String pesos(Decimal valor) => '\$ ${mostrarPrecio(valor)}';

/// "3 fiados · último 9 nov." o "Al día", como en `mClientes`.
String subtituloCliente(Cliente cliente) {
  final pendientes = cliente.obtenerFiadosPendientes();
  if (pendientes.isEmpty) return 'Al día';
  final ultimo = pendientes
      .map((f) => f.getFechaInicio())
      .reduce((a, b) => a.isAfter(b) ? a : b);
  final cuantos = pendientes.length == 1
      ? '1 fiado'
      : '${pendientes.length} fiados';
  return '$cuantos · último ${fechaCorta(ultimo)}';
}

/// "Eliminar datos del cliente" (CUS-21, mockup `Cliente`): pide la
/// confirmación (RNF-26), llama al view model y muestra el resultado.
/// [onEliminado] se llama solo si se eliminó, para volver a la lista.
class BotonEliminarCliente extends StatelessWidget {
  const BotonEliminarCliente({
    super.key,
    required this.vm,
    required this.cliente,
    this.onEliminado,
  });

  final FiadosViewModel vm;
  final Cliente cliente;
  final VoidCallback? onEliminado;

  static const pregunta = '¿Confirma que desea eliminar los datos del cliente?';

  Future<void> _eliminar(BuildContext context) async {
    final mensajes = ScaffoldMessenger.of(context);
    final confirmado = await pedirConfirmacion(
      context,
      pregunta: pregunta,
      textoConfirmar: 'Eliminar',
    );
    if (!confirmado) return;
    final eliminado = await vm.eliminarCliente(cliente);
    // El error también va en un aviso flotante: con varios fiados el botón
    // queda abajo y la tarjeta de aviso de arriba no se vería.
    mensajes.showSnackBar(
      SnackBar(
        content: Text(
          eliminado
              ? FiadosViewModel.mensajeClienteEliminado
              : (vm.aviso ?? FiadosViewModel.mensajeErrorEliminar),
        ),
      ),
    );
    if (eliminado) onEliminado?.call();
  }

  @override
  Widget build(BuildContext context) => BotonDestructivo(
    key: const Key('cliente_eliminar'),
    texto: 'Eliminar datos del cliente',
    icono: Icons.delete_outline,
    expandido: true,
    onPressed: () => _eliminar(context),
  );
}

/// Fila de un cliente en la lista: nombre, cuántos fiados y lo que debe.
class FilaCliente extends StatelessWidget {
  const FilaCliente({
    super.key,
    required this.cliente,
    required this.saldo,
    required this.onTap,
    this.elegida = false,
    this.conFlecha = true,
  });

  final Cliente cliente;
  final Decimal saldo;
  final VoidCallback onTap;
  final bool elegida;
  final bool conFlecha;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final extra = tema.extension<ColoresExtraGip>()!;
    final debe = saldo > Decimal.zero;
    return Semantics(
      button: true,
      selected: elegida,
      child: Material(
        color: elegida ? esquema.primaryContainer : esquema.surface,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.getNombre(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtituloCliente(cliente),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    pesos(saldo),
                    style: tema.textTheme.titleSmall
                        ?.copyWith(
                          color: debe
                              ? extra.errorTexto
                              : esquema.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        )
                        .cifrasTabulares,
                  ),
                  if (conFlecha) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: esquema.onSurfaceVariant),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Teléfono, "Debe en total" y los fiados pendientes de un cliente, cada uno
/// con "Fió $ X · abonó $ Y" y su saldo (mockups `Cliente` y `wClientes`).
/// Con [onElegirFiado] las filas se pueden tocar para elegir a cuál fiado se
/// abona (web).
class ResumenCliente extends StatelessWidget {
  const ResumenCliente({
    super.key,
    required this.cliente,
    required this.saldoTotal,
    this.accion,
    this.fiadoElegido,
    this.onElegirFiado,
  });

  final Cliente cliente;
  final Decimal saldoTotal;

  /// Botón bajo el saldo (móvil: "Registrar abono").
  final Widget? accion;
  final Fiado? fiadoElegido;
  final ValueChanged<Fiado>? onElegirFiado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final debe = saldoTotal > Decimal.zero;
    final pendientes = cliente.obtenerFiadosPendientes().toList()
      ..sort((a, b) => a.getFechaInicio().compareTo(b.getFechaInicio()));
    final separador = Divider(height: 1, thickness: 1, color: extra.separador);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TarjetaGip(
          radio: FormaGip.radioTarjetaMovil,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (cliente.getTelefono().isNotEmpty) ...[
                Text(
                  'Tel. ${cliente.getTelefono()}',
                  style: tema.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'Debe en total',
                      style: tema.textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    pesos(saldoTotal),
                    key: const Key('cliente_saldo_total'),
                    style: tema.textTheme.headlineMedium
                        ?.copyWith(
                          color: debe
                              ? extra.errorTexto
                              : tema.colorScheme.onSurfaceVariant,
                        )
                        .cifrasTabulares,
                  ),
                ],
              ),
              if (accion != null) ...[const SizedBox(height: 16), accion!],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Fiados pendientes',
                style: tema.textTheme.titleMedium,
              ),
            ),
            Text(
              pendientes.length == 1
                  ? '1 fiado'
                  : '${pendientes.length} fiados',
              style: tema.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 10),
        TarjetaGip(
          radio: FormaGip.radioTarjetaMovil,
          child: pendientes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No tiene fiados pendientes',
                    key: const Key('cliente_sin_fiados'),
                    style: tema.textTheme.bodyMedium,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, fiado) in pendientes.indexed) ...[
                      if (i > 0) separador,
                      _FilaFiado(
                        fiado: fiado,
                        elegida: fiadoElegido?.getId() == fiado.getId(),
                        onTap: onElegirFiado == null
                            ? null
                            : () => onElegirFiado!(fiado),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _FilaFiado extends StatelessWidget {
  const _FilaFiado({
    required this.fiado,
    required this.elegida,
    required this.onTap,
  });

  final Fiado fiado;
  final bool elegida;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final extra = tema.extension<ColoresExtraGip>()!;
    final abonado = fiado.getMontoInicial() - fiado.getSaldoPendiente();
    final detalle = abonado > Decimal.zero
        ? 'Fió ${pesos(fiado.getMontoInicial())} · abonó ${pesos(abonado)}'
        : 'Fió ${pesos(fiado.getMontoInicial())} · sin abonos';
    return Material(
      color: elegida ? esquema.primaryContainer : esquema.surface,
      child: InkWell(
        key: Key('fiado_${fiado.getId()}'),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fechaLarga(fiado.getFechaInicio()),
                        style: tema.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(detalle, style: tema.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  pesos(fiado.getSaldoPendiente()),
                  style: tema.textTheme.titleSmall
                      ?.copyWith(
                        color: extra.errorTexto,
                        fontWeight: FontWeight.w700,
                      )
                      .cifrasTabulares,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cuerpo del formulario de abono, igual en el móvil y en la web: monto,
/// medio (Efectivo o Nequi) y la referencia de Nequi, que es opcional.
/// El texto del campo de monto sigue a [AbonoViewModel.montoTexto] cuando se
/// elige otro fiado.
class CamposAbono extends StatefulWidget {
  const CamposAbono({super.key, required this.vm});

  final AbonoViewModel vm;

  @override
  State<CamposAbono> createState() => _CamposAbonoState();
}

class _CamposAbonoState extends State<CamposAbono> {
  late final TextEditingController _monto = TextEditingController(
    text: widget.vm.montoTexto,
  );
  final _referencia = TextEditingController();
  Fiado? _fiadoVisto;

  @override
  void initState() {
    super.initState();
    _fiadoVisto = widget.vm.fiado;
  }

  @override
  void dispose() {
    _monto.dispose();
    _referencia.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    if (!identical(_fiadoVisto, vm.fiado)) {
      _fiadoVisto = vm.fiado;
      _monto.text = vm.montoTexto;
    }
    final tema = Theme.of(context);
    final fiado = vm.fiado;
    final saldo = fiado?.getSaldoPendiente();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoGip(
          etiqueta: '¿Cuánto abona?',
          controlador: _monto,
          campoKey: const Key('abono_monto'),
          prefijo: r'$ ',
          alto: 64,
          estiloTexto: tema.textTheme.headlineMedium?.cifrasTabulares,
          tipoTeclado: TextInputType.number,
          ayuda: saldo == null
              ? 'No puede ser mayor que el saldo del fiado: el abono no da '
                    'cambio.'
              : 'Máximo ${pesos(saldo)}: el abono no da cambio.',
          error: vm.errorMonto,
          onChanged: vm.cambiarMonto,
        ),
        const SizedBox(height: 16),
        Text('Medio de pago', style: tema.textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<MedioPago>(
          key: const Key('abono_medio'),
          segments: const [
            ButtonSegment(value: MedioPago.efectivo, label: Text('Efectivo')),
            ButtonSegment(value: MedioPago.nequi, label: Text('Nequi')),
          ],
          selected: {vm.medio},
          showSelectedIcon: false,
          onSelectionChanged: (s) => vm.elegirMedio(s.single),
          style: SegmentedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        if (vm.medio == MedioPago.nequi) ...[
          const SizedBox(height: 16),
          CampoGip(
            etiqueta: 'Referencia Nequi (opcional)',
            controlador: _referencia,
            campoKey: const Key('abono_referencia'),
            icono: Icons.tag,
            onChanged: vm.cambiarReferencia,
          ),
        ],
      ],
    );
  }
}

/// Fiados entre los que se elige a cuál se abona (móvil, `mAbono`).
class ListaFiadosParaAbono extends StatelessWidget {
  const ListaFiadosParaAbono({super.key, required this.vm});

  final AbonoViewModel vm;

  @override
  Widget build(BuildContext context) {
    final extra = Theme.of(context).extension<ColoresExtraGip>()!;
    final separador = Divider(height: 1, thickness: 1, color: extra.separador);
    return TarjetaGip(
      radio: FormaGip.radioTarjetaMovil,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, fiado) in vm.fiados.indexed) ...[
            if (i > 0) separador,
            OpcionRadio(
              key: Key('abono_fiado_${fiado.getId()}'),
              titulo: fechaLarga(fiado.getFechaInicio()),
              subtitulo: _detalle(fiado),
              valor: pesos(fiado.getSaldoPendiente()),
              valorEnRojo: true,
              elegida: vm.fiado?.getId() == fiado.getId(),
              onTap: () => vm.elegirFiado(fiado),
            ),
          ],
        ],
      ),
    );
  }

  static String _detalle(Fiado fiado) {
    final abonado = fiado.getMontoInicial() - fiado.getSaldoPendiente();
    return abonado > Decimal.zero
        ? 'Fió ${pesos(fiado.getMontoInicial())} · abonó ${pesos(abonado)}'
        : 'Fió ${pesos(fiado.getMontoInicial())} · sin abonos';
  }
}

/// "Con este abono, el fiado del 28 de oct. queda saldado." en verde.
class AvisoSaldado extends StatelessWidget {
  const AvisoSaldado({super.key, required this.fiado});

  final Fiado fiado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return Container(
      key: const Key('abono_saldado'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: esquema.primaryContainer,
        borderRadius: BorderRadius.circular(FormaGip.radioCampo),
        border: Border.all(color: esquema.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check, color: esquema.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        'Con este abono, el fiado del '
                        '${fechaCorta(fiado.getFechaInicio())} queda ',
                  ),
                  const TextSpan(
                    text: 'saldado',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              style: tema.textTheme.bodyMedium?.copyWith(
                color: esquema.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón "Registrar abono de $ N" (móvil) o "Registrar abono" (web).
class BotonRegistrarAbono extends StatelessWidget {
  const BotonRegistrarAbono({
    super.key,
    required this.vm,
    required this.onPressed,
    this.conMonto = true,
  });

  final AbonoViewModel vm;
  final VoidCallback onPressed;
  final bool conMonto;

  @override
  Widget build(BuildContext context) {
    final monto = vm.montoParaBoton;
    return BotonPrimario(
      key: const Key('abono_registrar'),
      texto: conMonto && monto != null
          ? 'Registrar abono de ${pesos(monto)}'
          : 'Registrar abono',
      icono: Icons.check,
      cargando: vm.registrando,
      onPressed: vm.registrando ? null : onPressed,
    );
  }
}
