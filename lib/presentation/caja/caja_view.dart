import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/presentation/caja/caja_view_model.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/mensaje_resultado.dart';
import 'package:gip/presentation/comun/nota_info.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:provider/provider.dart';

/// Pantalla Caja (CUS-11, mockups `mCaja` y `wCaja`, con los componentes del
/// rediseño): el formulario "Anotar movimiento" del propietario.
///
/// No se muestran "Debe haber en caja", "Entró hoy", "Gastos del negocio",
/// "Para la casa", "Movimientos de hoy", "Ventas de hoy", "Cerrar caja" ni
/// "Abierta desde": el caso de uso no los entrega (llegan con CUS-14 y CUS-20,
/// DI-36).
class CajaView extends StatefulWidget {
  const CajaView({super.key});

  @override
  State<CajaView> createState() => _CajaViewState();
}

class _CajaViewState extends State<CajaView> {
  final _valor = TextEditingController();
  final _descripcion = TextEditingController();

  @override
  void dispose() {
    _valor.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _anotar() async {
    FocusScope.of(context).unfocus();
    final registrado = await context.read<CajaViewModel>().anotar(
      valor: _valor.text,
      descripcion: _descripcion.text,
    );
    if (registrado) {
      _valor.clear();
      _descripcion.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CajaViewModel>();
    final web = FormaGip.esWeb(context);
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: ListView(
              padding: web
                  ? const EdgeInsets.fromLTRB(44, 36, 44, 48)
                  : const EdgeInsets.fromLTRB(16, 28, 16, 24),
              children: [
                EncabezadoPantalla(titulo: web ? 'Caja de hoy' : 'Caja'),
                SizedBox(height: web ? 24 : 16),
                Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: _tarjetaAnotar(vm, web),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjetaAnotar(CajaViewModel vm, bool web) {
    final tema = Theme.of(context);
    final habilitado = !vm.guardando;
    final valor = CampoGip(
      etiqueta: 'Valor',
      controlador: _valor,
      campoKey: const Key('caja_valor'),
      prefijo: r'$ ',
      habilitado: habilitado,
      tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
      accionTeclado: TextInputAction.next,
    );
    final descripcion = CampoGip(
      etiqueta: '¿En qué?',
      controlador: _descripcion,
      campoKey: const Key('caja_descripcion'),
      habilitado: habilitado,
      mayusculas: TextCapitalization.sentences,
      accionTeclado: TextInputAction.done,
      onSubmitted: (_) => _anotar(),
    );
    final registrado = vm.registrado;
    return TarjetaGip(
      key: const Key('caja_tarjeta_anotar'),
      padding: EdgeInsets.all(web ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Anotar movimiento', style: tema.textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<TipoMovimientoCaja>(
            key: const Key('caja_tipo'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: TipoMovimientoCaja.egreso,
                label: Text('Sale dinero'),
              ),
              ButtonSegment(
                value: TipoMovimientoCaja.ingreso,
                label: Text('Entra dinero'),
              ),
            ],
            selected: {vm.tipo},
            onSelectionChanged: habilitado
                ? (s) => vm.elegirTipo(s.single)
                : null,
          ),
          const SizedBox(height: 12),
          SegmentedButton<ClasificacionMovimiento>(
            key: const Key('caja_clasificacion'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ClasificacionMovimiento.negocio,
                label: Text('Del negocio'),
              ),
              ButtonSegment(
                value: ClasificacionMovimiento.personal,
                label: Text('Personal'),
              ),
            ],
            selected: {vm.clasificacion},
            onSelectionChanged: habilitado
                ? (s) => vm.elegirClasificacion(s.single)
                : null,
          ),
          const SizedBox(height: 16),
          if (web) ...[
            valor,
            const SizedBox(height: 16),
            descripcion,
            const SizedBox(height: 16),
            const NotaInfo(
              texto:
                  'Las anulaciones de ventas se anotan solas; no se escriben '
                  'aquí.',
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: valor),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: descripcion),
              ],
            ),
          if (vm.error != null) ...[
            const SizedBox(height: 16),
            MensajeResultado(texto: vm.error!, esError: true),
          ],
          if (registrado != null) ...[
            const SizedBox(height: 16),
            MensajeResultado(
              key: const Key('caja_registrado'),
              texto: 'Movimiento registrado: ${_resumen(registrado)}',
              esError: false,
            ),
          ],
          const SizedBox(height: 16),
          BotonPrimario(
            key: const Key('caja_anotar'),
            texto: web ? 'Anotar movimiento' : 'Anotar',
            icono: Icons.add,
            cargando: vm.guardando,
            onPressed: _anotar,
          ),
        ],
      ),
    );
  }

  /// "Hielo · − $ 12.000 · Del negocio".
  static String _resumen(MovimientoCaja m) {
    final signo = m.esIngreso() ? '+' : '−';
    final clase = m.esDelNegocio() ? 'Del negocio' : 'Personal';
    final partes = [
      if (m.getDescripcion().isNotEmpty) m.getDescripcion(),
      '$signo \$ ${mostrarPrecio(m.getValor())}',
      clase,
    ];
    return partes.join(' · ');
  }
}
