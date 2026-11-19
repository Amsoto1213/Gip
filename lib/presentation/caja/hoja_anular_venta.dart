import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/presentation/caja/ventas_hoy_view_model.dart';
import 'package:gip/presentation/caja/widgets_caja.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/selector_filtro.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';

/// Motivos que ofrece la confirmación (mockups `Anular` y `wAnular`). "Otro…"
/// pide escribir el motivo.
enum _Motivo { errorAlCobrar, clienteDevolvio, otro }

/// Pregunta "¿Confirma la anulación de la venta?" (CUS-20, paso 12): en la web
/// un diálogo y en el móvil una hoja desde abajo. Dice qué va a pasar y pide el
/// motivo (obligatorio). Termina con el motivo escrito, o con null si el
/// propietario no confirma ("No, dejarla como está", tocar fuera o atrás).
Future<String?> pedirConfirmacionAnulacion(
  BuildContext context, {
  required Venta venta,
  required String detalle,
  required ResumenAnulacion resumen,
}) {
  final contenido = _ContenidoAnular(
    venta: venta,
    detalle: detalle,
    resumen: resumen,
    enHoja: !FormaGip.esWeb(context),
  );
  if (FormaGip.esWeb(context)) {
    return showDialog<String>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim,
      builder: (_) => Dialog(
        key: const Key('anular_dialogo'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FormaGip.radioTarjeta),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: contenido,
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    barrierColor: Theme.of(context).colorScheme.scrim,
    builder: (_) => Padding(
      key: const Key('anular_hoja'),
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(child: contenido),
    ),
  );
}

class _ContenidoAnular extends StatefulWidget {
  const _ContenidoAnular({
    required this.venta,
    required this.detalle,
    required this.resumen,
    required this.enHoja,
  });

  final Venta venta;
  final String detalle;
  final ResumenAnulacion resumen;
  final bool enHoja;

  @override
  State<_ContenidoAnular> createState() => _ContenidoAnularState();
}

class _ContenidoAnularState extends State<_ContenidoAnular> {
  _Motivo _motivo = _Motivo.errorAlCobrar;
  final _otro = TextEditingController();

  @override
  void dispose() {
    _otro.dispose();
    super.dispose();
  }

  /// Motivo listo para guardar, o null si falta escribirlo.
  String? get _motivoEscrito => switch (_motivo) {
    _Motivo.errorAlCobrar => 'Error al cobrar',
    _Motivo.clienteDevolvio => 'Cliente devolvió',
    _Motivo.otro => _otro.text.trim().isEmpty ? null : _otro.text.trim(),
  };

  void _confirmar() {
    final motivo = _motivoEscrito;
    if (motivo != null) Navigator.of(context).pop(motivo);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final r = widget.resumen;
    final hora = horaDe(widget.venta.getFecha());
    final lineas = <(IconData, String)>[
      if (r.productos > 0)
        (
          Icons.inventory_2_outlined,
          r.productos == 1
              ? 'El producto vuelve al surtido.'
              : 'Los ${r.productos} productos vuelven al surtido.',
        ),
      if (r.salenDeCaja > Decimal.zero)
        (
          Icons.payments_outlined,
          'Salen ${pesos(r.salenDeCaja)} de la caja de hoy.',
        ),
      if (r.fiadoAnulado > Decimal.zero)
        (
          Icons.menu_book_outlined,
          'El fiado de ${pesos(r.fiadoAnulado)} queda anulado.',
        ),
      if (r.devolverPorNequi > Decimal.zero)
        (
          Icons.phone_android_outlined,
          'Devuelva ${pesos(r.devolverPorNequi)} por Nequi: no sale de la '
              'caja.',
        ),
      (
        Icons.person_outline,
        'Queda anotado que usted la anuló. No se puede deshacer.',
      ),
    ];
    final botonSi = BotonDestructivo(
      key: const Key('anular_confirmar'),
      texto: 'Sí, anular venta',
      relleno: true,
      alto: 56,
      expandido: true,
      onPressed: _motivoEscrito == null ? null : _confirmar,
    );
    final botonNo = BotonSecundario(
      key: const Key('anular_cancelar'),
      texto: 'No, dejarla como está',
      alto: 56,
      expandido: true,
      onPressed: () => Navigator.of(context).pop(),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: esquema.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: esquema.error),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  '¿Anular la venta de las $hora?',
                  style: tema.textTheme.titleLarge,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: tema.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(FormaGip.radioCampo),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(widget.detalle, style: tema.textTheme.bodyLarge),
              ),
              const SizedBox(width: 12),
              Text(
                pesos(widget.venta.getTotal()),
                style: tema.textTheme.titleMedium?.cifrasTabulares,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final (icono, texto) in lineas)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, size: 22, color: esquema.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(child: Text(texto, style: tema.textTheme.bodyLarge)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text('Motivo (obligatorio)', style: tema.textTheme.titleMedium),
        const SizedBox(height: 10),
        SelectorFiltro<_Motivo>(
          prefijoClave: 'anular_motivo',
          elegido: _motivo,
          onElegir: (m) => setState(() => _motivo = m),
          opciones: const [
            (valor: _Motivo.errorAlCobrar, etiqueta: 'Error al cobrar'),
            (valor: _Motivo.clienteDevolvio, etiqueta: 'Cliente devolvió'),
            (valor: _Motivo.otro, etiqueta: 'Otro…'),
          ],
        ),
        if (_motivo == _Motivo.otro) ...[
          const SizedBox(height: 12),
          CampoGip(
            etiqueta: '',
            controlador: _otro,
            campoKey: const Key('anular_motivo_otro'),
            pista: 'Escriba el motivo',
            mayusculas: TextCapitalization.sentences,
            accionTeclado: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _confirmar(),
          ),
        ],
        const SizedBox(height: 20),
        if (widget.enHoja) ...[
          botonSi,
          const SizedBox(height: 10),
          botonNo,
        ] else
          Row(
            children: [
              Expanded(child: botonNo),
              const SizedBox(width: 14),
              Expanded(child: botonSi),
            ],
          ),
      ],
    );
  }
}
