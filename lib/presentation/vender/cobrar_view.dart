import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/vender/cobrar_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Cobrar (CUS-02, mockup `Cobro`): efectivo con cambio, Nequi y
/// "Confirmar venta". Fiado llega con CUS-07. En la web también es una
/// pantalla aparte, no el panel del mockup `Vender` (DI-21). Al confirmar
/// vuelve a Vender con verdadero.
class CobrarView extends StatefulWidget {
  const CobrarView({super.key});

  @override
  State<CobrarView> createState() => _CobrarViewState();
}

class _CobrarViewState extends State<CobrarView> {
  final _efectivo = TextEditingController();
  final _nequiMonto = TextEditingController();
  final _nequiReferencia = TextEditingController();

  @override
  void dispose() {
    _efectivo.dispose();
    _nequiMonto.dispose();
    _nequiReferencia.dispose();
    super.dispose();
  }

  CobrarViewModel get _vm => context.read<CobrarViewModel>();

  void _cambiarNequi() =>
      _vm.cambiarNequi(_nequiMonto.text, _nequiReferencia.text);

  void _elegirEfectivo(Decimal valor) {
    _efectivo.text = mostrarPrecio(valor);
    _vm.elegirEfectivo(valor);
  }

  void _quitarContado() {
    _efectivo.clear();
    _vm.quitarContado();
  }

  void _quitarNequi() {
    _nequiMonto.clear();
    _nequiReferencia.clear();
    _vm.quitarNequi();
  }

  Future<void> _confirmar() async {
    FocusScope.of(context).unfocus();
    final registrada = await _vm.confirmar();
    if (registrada && mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CobrarViewModel>();
    final tema = Theme.of(context);
    final n = vm.cantidadProductos;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const _Encabezado(),
                const SizedBox(height: 16),
                _TarjetaTotal(
                  texto:
                      'Total a pagar · $n ${n == 1 ? 'producto' : 'productos'}',
                  total: vm.total,
                ),
                const SizedBox(height: 20),
                Text('¿Cómo paga?', style: tema.textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<MedioCobro>(
                  segments: const [
                    ButtonSegment(
                      value: MedioCobro.efectivo,
                      icon: Icon(Icons.payments_outlined),
                      label: Text('Efectivo'),
                    ),
                    ButtonSegment(
                      value: MedioCobro.nequi,
                      icon: Icon(Icons.phone_android),
                      label: Text('Nequi'),
                    ),
                  ],
                  selected: {vm.medio},
                  onSelectionChanged: (s) => vm.elegirMedio(s.single),
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: vm.medio == MedioCobro.efectivo
                        ? _panelEfectivo(vm)
                        : _panelNequi(vm),
                  ),
                ),
                const SizedBox(height: 16),
                _ResumenPagos(
                  vm: vm,
                  onQuitarContado: _quitarContado,
                  onQuitarNequi: _quitarNequi,
                ),
                if (vm.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    vm.error!,
                    key: const Key('cobrar_error'),
                    style: TextStyle(color: tema.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    key: const Key('cobrar_confirmar'),
                    onPressed: vm.pagoCompleto && !vm.confirmando
                        ? _confirmar
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                    ),
                    icon: vm.confirmando
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Confirmar venta'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Se descuenta del surtido y entra a la caja en un solo '
                    'paso.',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panelEfectivo(CobrarViewModel vm) {
    final tema = Theme.of(context);
    if (vm.efectivoACubrir <= Decimal.zero) {
      return Text('Nequi ya cubre el total', style: tema.textTheme.bodyLarge);
    }
    final contado = vm.contado;
    final sugerencias = vm.sugerenciasEfectivo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Efectivo recibido',
          style: tema.textTheme.titleSmall?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('cobrar_efectivo'),
          controller: _efectivo,
          onChanged: vm.cambiarEfectivo,
          keyboardType: TextInputType.number,
          style: tema.textTheme.headlineSmall,
          decoration: InputDecoration(
            prefixText: r'$ ',
            hintText: mostrarPrecio(vm.efectivoACubrir),
            errorText: vm.errorEfectivo,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, valor) in sugerencias.indexed)
              ChoiceChip(
                key: Key('cobrar_sugerencia_$i'),
                label: Text(i == 0 ? 'Justo' : _enMiles(valor)),
                selected: vm.efectivoRecibido == valor,
                onSelected: (_) => _elegirEfectivo(valor),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
          ],
        ),
        if (contado != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tema.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Cambio a devolver',
                    style: tema.textTheme.titleMedium?.copyWith(
                      color: tema.colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  '\$ ${mostrarPrecio(contado.getCambio())}',
                  key: const Key('cobrar_cambio'),
                  style: tema.textTheme.headlineSmall?.copyWith(
                    color: tema.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _panelNequi(CobrarViewModel vm) {
    final tema = Theme.of(context);
    final etiqueta = tema.textTheme.titleSmall?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Monto por Nequi', style: etiqueta),
        const SizedBox(height: 8),
        TextField(
          key: const Key('cobrar_nequi_monto'),
          controller: _nequiMonto,
          onChanged: (_) => _cambiarNequi(),
          keyboardType: TextInputType.number,
          style: tema.textTheme.headlineSmall,
          decoration: InputDecoration(
            prefixText: r'$ ',
            hintText: mostrarPrecio(vm.total),
            errorText: vm.errorNequi,
          ),
        ),
        const SizedBox(height: 16),
        Text('Referencia de Nequi (opcional)', style: etiqueta),
        const SizedBox(height: 8),
        TextField(
          key: const Key('cobrar_nequi_referencia'),
          controller: _nequiReferencia,
          onChanged: (_) => _cambiarNequi(),
          decoration: const InputDecoration(hintText: 'Ej.: 4471'),
        ),
      ],
    );
  }

  /// 15000 → "15 mil"; si no es de miles exactos, el precio completo.
  static String _enMiles(Decimal valor) {
    final mil = Decimal.fromInt(1000);
    final miles = (valor / mil).toDecimal(scaleOnInfinitePrecision: 3);
    return miles.isInteger
        ? '${mostrarPrecio(miles)} mil'
        : '\$ ${mostrarPrecio(valor)}';
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(false),
          tooltip: 'Volver',
          iconSize: 28,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VENDER',
              style: tema.textTheme.labelMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            Semantics(
              header: true,
              child: Text('Cobrar', style: tema.textTheme.headlineLarge),
            ),
          ],
        ),
      ],
    );
  }
}

class _TarjetaTotal extends StatelessWidget {
  const _TarjetaTotal({required this.texto, required this.total});

  final String texto;
  final Decimal total;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esquema.inverseSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texto,
            style: tema.textTheme.bodyLarge?.copyWith(
              color: esquema.onInverseSurface,
            ),
          ),
          Text(
            '\$ ${mostrarPrecio(total)}',
            key: const Key('cobrar_total'),
            style: tema.textTheme.displaySmall?.copyWith(
              color: esquema.onInverseSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenPagos extends StatelessWidget {
  const _ResumenPagos({
    required this.vm,
    required this.onQuitarContado,
    required this.onQuitarNequi,
  });

  final CobrarViewModel vm;
  final VoidCallback onQuitarContado;
  final VoidCallback onQuitarNequi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final contado = vm.contado;
    final nequi = vm.nequi;
    Widget fila(String clave, String texto, Decimal valor, VoidCallback f) =>
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Expanded(child: Text(texto, style: tema.textTheme.bodyLarge)),
                Text(
                  '\$ ${mostrarPrecio(valor)}',
                  style: tema.textTheme.titleMedium,
                ),
                IconButton(
                  key: Key('cobrar_quitar_$clave'),
                  onPressed: f,
                  tooltip: 'Quitar',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        );
    final referencia = nequi?.getReferencia();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (contado != null)
          fila(
            'contado',
            'Efectivo · recibió \$ ${mostrarPrecio(contado.getMontoRecibido())}',
            contado.calcularMontoCubierto(),
            onQuitarContado,
          ),
        if (nequi != null)
          fila(
            'nequi',
            referencia == null ? 'Nequi' : 'Nequi · ref. $referencia',
            nequi.getMonto(),
            onQuitarNequi,
          ),
        if (vm.pagoCompleto)
          Row(
            children: [
              Icon(Icons.check, color: tema.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pago completo · cambio '
                  '\$ ${mostrarPrecio(contado?.getCambio() ?? Decimal.zero)}',
                  key: const Key('cobrar_pago_completo'),
                  style: tema.textTheme.titleSmall?.copyWith(
                    color: tema.colorScheme.primary,
                  ),
                ),
              ),
            ],
          )
        else if (vm.faltante > Decimal.zero)
          Text(
            'Falta \$ ${mostrarPrecio(vm.faltante)}',
            key: const Key('cobrar_falta'),
            style: tema.textTheme.titleSmall?.copyWith(
              color: tema.extension<ColoresExtraGip>()!.alertaTexto,
            ),
          ),
      ],
    );
  }
}
