import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/vender/cobrar_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Cobrar (CUS-02, mockup `Cobro`, con los componentes del
/// rediseño): efectivo con cambio, Nequi y
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
    final web = FormaGip.esWeb(context);
    final margen = web ? 44.0 : 16.0;
    final n = vm.cantidadProductos;
    final error = vm.error;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 728),
            child: ListView(
              padding: EdgeInsets.fromLTRB(margen, web ? 32 : 16, margen, 24),
              children: [
                EncabezadoPantalla(
                  titulo: 'Cobrar',
                  seccion: 'Vender',
                  onVolver: () => context.pop(false),
                ),
                SizedBox(height: web ? 24 : 16),
                _TarjetaTotal(
                  texto:
                      'Total a pagar · $n ${n == 1 ? 'producto' : 'productos'}',
                  total: vm.total,
                ),
                const SizedBox(height: 20),
                Text('¿Cómo paga?', style: tema.textTheme.labelMedium),
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
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => vm.elegirMedio(s.single),
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
                const SizedBox(height: 16),
                TarjetaGip(
                  padding: const EdgeInsets.all(20),
                  child: vm.medio == MedioCobro.efectivo
                      ? _panelEfectivo(vm)
                      : _panelNequi(vm),
                ),
                const SizedBox(height: 16),
                _ResumenPagos(
                  vm: vm,
                  onQuitarContado: _quitarContado,
                  onQuitarNequi: _quitarNequi,
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: tema.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: tema.colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            error,
                            key: const Key('cobrar_error'),
                            style: TextStyle(
                              color: tema.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
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
            constraints: const BoxConstraints(maxWidth: 728),
            child: Padding(
              padding: EdgeInsets.fromLTRB(margen, 8, margen, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BotonPrimario(
                    key: const Key('cobrar_confirmar'),
                    texto: 'Confirmar venta',
                    icono: Icons.check,
                    cargando: vm.confirmando,
                    onPressed: vm.pagoCompleto && !vm.confirmando
                        ? _confirmar
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Se descuenta del surtido y entra a la caja en un solo '
                    'paso.',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodySmall?.copyWith(fontSize: 13),
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
        CampoGip(
          etiqueta: 'Efectivo recibido',
          controlador: _efectivo,
          campoKey: const Key('cobrar_efectivo'),
          icono: Icons.payments_outlined,
          prefijo: r'$ ',
          pista: mostrarPrecio(vm.efectivoACubrir),
          error: vm.errorEfectivo,
          tipoTeclado: TextInputType.number,
          onChanged: vm.cambiarEfectivo,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: tema.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
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
                  style: tema.textTheme.headlineSmall
                      ?.copyWith(color: tema.colorScheme.primary)
                      .cifrasTabulares,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _panelNequi(CobrarViewModel vm) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CampoGip(
        etiqueta: 'Monto por Nequi',
        controlador: _nequiMonto,
        campoKey: const Key('cobrar_nequi_monto'),
        icono: Icons.phone_android,
        prefijo: r'$ ',
        pista: mostrarPrecio(vm.total),
        error: vm.errorNequi,
        tipoTeclado: TextInputType.number,
        onChanged: (_) => _cambiarNequi(),
      ),
      const SizedBox(height: 16),
      CampoGip(
        etiqueta: 'Referencia de Nequi (opcional)',
        controlador: _nequiReferencia,
        campoKey: const Key('cobrar_nequi_referencia'),
        icono: Icons.tag,
        pista: 'Ej.: 4471',
        onChanged: (_) => _cambiarNequi(),
      ),
    ],
  );

  /// 15000 → "15 mil"; si no es de miles exactos, el precio completo.
  static String _enMiles(Decimal valor) {
    final mil = Decimal.fromInt(1000);
    final miles = (valor / mil).toDecimal(scaleOnInfinitePrecision: 3);
    return miles.isInteger
        ? '${mostrarPrecio(miles)} mil'
        : '\$ ${mostrarPrecio(valor)}';
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
    final extra = tema.extension<ColoresExtraGip>()!;
    // Caja oscura como la del resumen de los movimientos (rediseño).
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: extra.navFondo,
        borderRadius: BorderRadius.circular(FormaGip.radioTarjeta),
        boxShadow: FormaGip.sombraElevada,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texto,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: extra.navTextoSecundario,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '\$ ${mostrarPrecio(total)}',
              key: const Key('cobrar_total'),
              style: tema.textTheme.headlineLarge
                  ?.copyWith(fontSize: 40, color: esquema.onPrimary)
                  .cifrasTabulares,
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TarjetaGip(
            radio: FormaGip.radioCajaIcono,
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Expanded(child: Text(texto, style: tema.textTheme.bodyLarge)),
                Text(
                  '\$ ${mostrarPrecio(valor)}',
                  style: tema.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)
                      .cifrasTabulares,
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
