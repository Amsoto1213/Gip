import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_caja/desglose_caja.dart';
import 'package:gip/presentation/caja/cierre_caja_view_model.dart';
import 'package:gip/presentation/caja/rutas_caja.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/mensaje_resultado.dart';
import 'package:gip/presentation/comun/nota_info.dart';
import 'package:gip/presentation/comun/tarjeta_diferencia.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Cierre de caja (CUS-14, mockups `mCierre` y `wCierre`, con los
/// componentes del rediseño): lo que debe haber en caja, el efectivo contado
/// con la diferencia a la vista y el cierre.
///
/// "Lo que debe haber" muestra con qué abrió la caja, lo que entró y salió por
/// clase y el total (DI-38). "Ventas" y "Abonos" van juntos en "Entró al
/// negocio", y los renglones de dinero personal que entró y devoluciones por
/// anulación solo salen si hay algo, para que siempre sumen. No lleva la frase
/// "La diferencia queda en el reporte del día" (DI-37).
class CierreCajaView extends StatefulWidget {
  const CierreCajaView({super.key});

  @override
  State<CierreCajaView> createState() => _CierreCajaViewState();
}

class _CierreCajaViewState extends State<CierreCajaView> {
  final _efectivo = TextEditingController();
  final _foco = FocusNode();

  @override
  void dispose() {
    _efectivo.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _volverACaja() => context.go(rutaPrincipalCaja);

  void _volverAContar() {
    _efectivo.clear();
    context.read<CierreCajaViewModel>().escribirEfectivo('');
    _foco.requestFocus();
  }

  Future<void> _cerrar() async {
    FocusScope.of(context).unfocus();
    await context.read<CierreCajaViewModel>().cerrar(_efectivo.text);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CierreCajaViewModel>();
    final web = FormaGip.esWeb(context);
    final cuerpo = _cuerpo(vm, web);
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: ListView(
              padding: web
                  ? const EdgeInsets.fromLTRB(44, 32, 44, 48)
                  : const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                EncabezadoPantalla(
                  titulo: web ? 'Cierre de caja' : 'Cerrar caja',
                  seccion: 'Caja',
                  miga: 'Cierre de caja',
                  onVolver: _volverACaja,
                ),
                SizedBox(height: web ? 24 : 16),
                cuerpo,
              ],
            ),
          ),
        ),
      ),
      // En el móvil los botones van fijos abajo (mockup `mCierre`).
      bottomNavigationBar: web || vm.saldoEsperado == null
          ? null
          : _BarraAcciones(hijos: _botones(vm)),
    );
  }

  Widget _cuerpo(CierreCajaViewModel vm, bool web) {
    if (vm.saldoEsperado == null) {
      if (vm.cargando) {
        return const Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (vm.error != null)
            MensajeResultado(texto: vm.error!, esError: true),
        ],
      );
    }
    final debeHaber = _TarjetaDebeHaber(desglose: vm.desglose!, web: web);
    final contado = _tarjetaContado(vm, web);
    if (!web) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [debeHaber, const SizedBox(height: 20), contado],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: debeHaber),
        const SizedBox(width: 24),
        Expanded(child: contado),
      ],
    );
  }

  Widget _tarjetaContado(CierreCajaViewModel vm, bool web) {
    final tema = Theme.of(context);
    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vm.cerrada) ..._resultado(vm) else ..._formulario(vm, web),
      ],
    );
    if (!web) return contenido;
    return TarjetaGip(
      key: const Key('cierre_tarjeta_contado'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            vm.cerrada ? 'Caja cerrada' : 'Lo que usted contó',
            style: tema.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          contenido,
          if (!vm.cerrada) ...[
            const SizedBox(height: 16),
            ..._botones(vm).expand((b) => [b, const SizedBox(height: 12)]),
          ] else ...[
            const SizedBox(height: 4),
            ..._botones(vm),
          ],
        ],
      ),
    );
  }

  List<Widget> _formulario(CierreCajaViewModel vm, bool web) {
    final tema = Theme.of(context);
    final previa = vm.vistaPrevia;
    return [
      if (!web) ...[
        Text('¿Cuánto efectivo contó?', style: tema.textTheme.titleMedium),
        const SizedBox(height: 8),
      ],
      CampoGip(
        etiqueta: web ? 'Efectivo contado' : '',
        controlador: _efectivo,
        campoKey: const Key('cierre_efectivo'),
        focusNode: _foco,
        prefijo: r'$ ',
        habilitado: !vm.cerrando,
        tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
        accionTeclado: TextInputAction.done,
        onChanged: vm.escribirEfectivo,
        onSubmitted: (_) => _cerrar(),
      ),
      if (previa != null) ...[
        const SizedBox(height: 16),
        TarjetaDiferencia(
          key: const Key('cierre_vista_previa'),
          tono: CierreCajaViewModel.tonoDe(previa),
          titulo: CierreCajaViewModel.tituloDe(previa),
          valor: CierreCajaViewModel.montoDe(previa),
        ),
      ],
      if (vm.error != null) ...[
        const SizedBox(height: 16),
        MensajeResultado(texto: vm.error!, esError: true),
      ],
      const SizedBox(height: 16),
      const NotaInfo(
        texto: 'Después de cerrar no se pueden anotar más movimientos de hoy.',
      ),
    ];
  }

  List<Widget> _resultado(CierreCajaViewModel vm) {
    final diferencia = vm.diferenciaFinal!;
    return [
      TarjetaDiferencia(
        key: const Key('cierre_resultado'),
        tono: CierreCajaViewModel.tonoDe(diferencia),
        titulo: CierreCajaViewModel.tituloDe(diferencia),
        valor: CierreCajaViewModel.montoDe(diferencia),
      ),
      const SizedBox(height: 16),
      const MensajeResultado(
        key: Key('cierre_cerrada'),
        texto: 'Caja cerrada. Ya no se pueden anotar más movimientos de hoy.',
        esError: false,
      ),
    ];
  }

  /// "Cerrar caja con faltante", "…con sobrante" o "Cerrar caja"; "Volver a
  /// contar" borra el efectivo. Cerrada, solo "Volver a Caja".
  List<Widget> _botones(CierreCajaViewModel vm) {
    if (vm.cerrada) {
      return [
        BotonPrimario(
          key: const Key('cierre_volver_caja'),
          texto: 'Volver a Caja',
          icono: Icons.arrow_back,
          onPressed: _volverACaja,
        ),
      ];
    }
    final previa = vm.vistaPrevia;
    final sufijo = switch (previa == null
        ? null
        : CierreCajaViewModel.tonoDe(previa)) {
      TonoDiferencia.faltante => ' con faltante',
      TonoDiferencia.sobrante => ' con sobrante',
      _ => '',
    };
    return [
      BotonPrimario(
        key: const Key('cierre_cerrar'),
        texto: 'Cerrar caja$sufijo',
        icono: Icons.lock_outline,
        cargando: vm.cerrando,
        onPressed: vm.efectivoContado == null ? null : _cerrar,
      ),
      BotonSecundario(
        key: const Key('cierre_volver_a_contar'),
        texto: 'Volver a contar',
        expandido: true,
        onPressed: vm.cerrando ? null : _volverAContar,
      ),
    ];
  }
}

/// Tarjeta "Lo que debe haber" (mockup `wCierre`): con qué abrió, lo que entró
/// y salió, y el total (DI-38).
class _TarjetaDebeHaber extends StatelessWidget {
  const _TarjetaDebeHaber({required this.desglose, required this.web});

  final DesgloseCaja desglose;
  final bool web;

  static String _pesos(Decimal v) => '\$ ${mostrarPrecio(v)}';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cero = Decimal.zero;
    final filas = <Widget>[
      _FilaDesglose('Abrió con', _pesos(desglose.baseApertura)),
      _FilaDesglose('+ Entró al negocio', _pesos(desglose.ingresosNegocio)),
      if (desglose.ingresosPersonales != cero)
        _FilaDesglose(
          '+ Dinero personal que entró',
          _pesos(desglose.ingresosPersonales),
        ),
      _FilaDesglose('− Gastos del negocio', _pesos(desglose.egresosNegocio)),
      _FilaDesglose('− Personal', _pesos(desglose.egresosPersonales)),
      if (desglose.devolucionesPorAnulacion != cero)
        _FilaDesglose(
          '− Devoluciones por anulación',
          _pesos(desglose.devolucionesPorAnulacion),
        ),
    ];
    return TarjetaGip(
      key: const Key('cierre_tarjeta_debe_haber'),
      padding: EdgeInsets.all(web ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (web) ...[
            Text('Lo que debe haber', style: tema.textTheme.titleLarge),
            const SizedBox(height: 8),
          ],
          ...filas,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('Debe haber', style: tema.textTheme.titleMedium),
              ),
              Text(
                _pesos(desglose.saldoEsperado),
                key: const Key('cierre_saldo_esperado'),
                style: tema.textTheme.headlineSmall?.cifrasTabulares,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Un renglón del desglose: nombre a la izquierda y valor a la derecha, con
/// una línea fina debajo.
class _FilaDesglose extends StatelessWidget {
  const _FilaDesglose(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: tema.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: tema.textTheme.bodyLarge)),
          Text(valor, style: tema.textTheme.bodyLarge?.cifrasTabulares),
        ],
      ),
    );
  }
}

/// Botones fijos abajo del móvil.
class _BarraAcciones extends StatelessWidget {
  const _BarraAcciones({required this.hijos});

  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: esquema.surface,
        border: Border(top: BorderSide(color: esquema.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < hijos.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                hijos[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
