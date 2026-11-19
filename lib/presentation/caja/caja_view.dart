import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/presentation/caja/caja_view_model.dart';
import 'package:gip/presentation/caja/rutas_caja.dart';
import 'package:gip/presentation/caja/widgets_caja.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/mensaje_resultado.dart';
import 'package:gip/presentation/comun/nota_info.dart';
import 'package:gip/presentation/comun/tarjeta_cifra.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Caja (CUS-11 y CUS-14, mockups `mCaja` y `wCaja`, con los
/// componentes del rediseño): con qué abrió la caja, lo que debe haber con
/// "Cerrar caja", las cifras del día, los movimientos de hoy y el formulario
/// "Anotar movimiento" del propietario (DI-38).
///
/// No se muestran "Ventas de hoy" (CUS-20), la hora de apertura ("Abierta
/// desde": la caja solo guarda el día), el nombre de quien anotó cada
/// movimiento (no se guarda) ni "Al día" (DI-36 y DI-38). "Para la casa" se
/// llama "Personal". Un empleado solo ve el formulario: la consulta se le
/// rechaza.
class CajaView extends StatefulWidget {
  const CajaView({super.key});

  @override
  State<CajaView> createState() => _CajaViewState();
}

class _CajaViewState extends State<CajaView> {
  final _valor = TextEditingController();
  final _descripcion = TextEditingController();

  /// La tarjeta del formulario cambia de lugar cuando llegan las cifras; con
  /// esta llave conserva lo que el tendero ya escribió y el foco.
  final _claveAnotar = GlobalKey();

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
                EncabezadoPantalla(
                  titulo: web ? 'Caja de hoy' : 'Caja',
                  contexto: vm.baseApertura == null
                      ? null
                      : 'Abrió con ${pesos(vm.baseApertura!)}',
                  accion: web && vm.desglose != null
                      ? BotonSecundario(
                          key: const Key('caja_cerrar'),
                          texto: 'Cerrar caja',
                          icono: Icons.lock_outline,
                          onPressed: () => context.go(rutaCierreCaja),
                        )
                      : null,
                ),
                SizedBox(height: web ? 24 : 16),
                if (vm.desglose == null)
                  Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: _tarjetaAnotar(vm, web),
                    ),
                  )
                else if (web)
                  ..._cuerpoWeb(vm)
                else
                  ..._cuerpoMovil(vm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cuatro cifras arriba; abajo la tabla de hoy y el formulario (`wCaja`).
  List<Widget> _cuerpoWeb(CajaViewModel vm) {
    final d = vm.desglose!;
    final gastos = d.cantidadEgresosNegocio;
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TarjetaCifra(
              etiqueta: 'Debe haber en caja',
              valor: pesos(d.saldoEsperado),
              valorKey: const Key('caja_saldo_esperado'),
              detalle: 'efectivo',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TarjetaCifra(
              etiqueta: 'Entró hoy',
              valor: pesos(d.ingresosNegocio),
              valorKey: const Key('caja_entro_hoy'),
              detalle: 'ingresos del negocio',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TarjetaCifra(
              etiqueta: 'Gastos del negocio',
              valor: pesos(d.egresosNegocio),
              valorKey: const Key('caja_gastos'),
              detalle: gastos == 1 ? '1 movimiento' : '$gastos movimientos',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TarjetaCifra(
              etiqueta: 'Personal',
              valor: pesos(d.egresosPersonales),
              valorKey: const Key('caja_personal'),
              detalle: 'aparte de la ganancia',
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TarjetaMovimientosHoy(movimientos: vm.movimientosDeHoy),
          ),
          const SizedBox(width: 24),
          SizedBox(width: 400, child: _tarjetaAnotar(vm, true)),
        ],
      ),
    ];
  }

  /// Saldo con "Cerrar caja", el formulario y la lista "Hoy" (`mCaja`).
  List<Widget> _cuerpoMovil(CajaViewModel vm) => [
    _tarjetaSaldo(vm),
    const SizedBox(height: 16),
    _tarjetaAnotar(vm, false),
    const SizedBox(height: 24),
    ListaMovimientosHoy(movimientos: vm.movimientosDeHoy),
  ];

  /// "Debe haber en caja" con la entrada a Cierre de caja (CUS-14).
  Widget _tarjetaSaldo(CajaViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TarjetaCifra(
          etiqueta: 'Debe haber en caja',
          valor: pesos(vm.saldoEsperado!),
          valorKey: const Key('caja_saldo_esperado'),
          detalle: 'efectivo',
        ),
        const SizedBox(height: 12),
        BotonSecundario(
          key: const Key('caja_cerrar'),
          texto: 'Cerrar caja',
          icono: Icons.lock_outline,
          expandido: true,
          onPressed: () => context.go(rutaCierreCaja),
        ),
      ],
    );
  }

  Widget _tarjetaAnotar(CajaViewModel vm, bool web) {
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
    return KeyedSubtree(
      key: _claveAnotar,
      child: _tarjetaAnotarContenido(vm, web, valor, descripcion, registrado),
    );
  }

  Widget _tarjetaAnotarContenido(
    CajaViewModel vm,
    bool web,
    Widget valor,
    Widget descripcion,
    MovimientoCaja? registrado,
  ) {
    final tema = Theme.of(context);
    final habilitado = !vm.guardando;
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
