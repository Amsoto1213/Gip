import 'package:flutter/material.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/presentation/caja/hoja_anular_venta.dart';
import 'package:gip/presentation/caja/rutas_caja.dart';
import 'package:gip/presentation/caja/ventas_hoy_view_model.dart';
import 'package:gip/presentation/caja/widgets_caja.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/mensaje_resultado.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/selector_filtro.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/fiados/formato_fecha.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Ventas de hoy (CUS-20, mockups `Anular` y `wAnular`, con los
/// componentes del rediseño): las ventas del periodo con su forma de pago y su
/// estado, y "Anular" con confirmación y motivo. En la web una tabla (hora,
/// productos, pago, total y la acción); en el móvil una fila por venta que se
/// toca para anular. Una venta anulada se queda en la lista, tachada y con la
/// etiqueta "Anulada".
///
/// No se muestran el equipo ni quién vendió: no se guardan (DI-39).
class VentasHoyView extends StatelessWidget {
  const VentasHoyView({super.key});

  void _volver(BuildContext context) => context.go(rutaPrincipalCaja);

  Future<void> _elegirFechas(
    BuildContext context,
    VentasHoyViewModel vm,
  ) async {
    final hoy = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(hoy.year, hoy.month, hoy.day),
      initialDateRange: DateTimeRange(start: vm.desde, end: vm.hasta),
    );
    if (rango != null) await vm.elegirFechas(rango.start, rango.end);
  }

  Future<void> _anular(
    BuildContext context,
    VentasHoyViewModel vm,
    Venta venta,
  ) async {
    final nombres = vm.nombresDe(venta);
    final detalle = [
      if (nombres.isNotEmpty) nombres.join(', '),
      VentasHoyViewModel.pagoDe(venta),
    ].join(' · ');
    final motivo = await pedirConfirmacionAnulacion(
      context,
      venta: venta,
      detalle: detalle,
      resumen: vm.resumenDe(venta),
    );
    if (motivo != null) await vm.anular(venta, motivo);
  }

  static String _titulo(VentasHoyViewModel vm) => switch (vm.periodo) {
    PeriodoVentas.hoy => 'Ventas de hoy',
    PeriodoVentas.ayer => 'Ventas de ayer',
    PeriodoVentas.fechas =>
      vm.desde == vm.hasta
          ? 'Ventas del ${fechaCorta(vm.desde)}'
          : 'Ventas del ${fechaCorta(vm.desde)} al ${fechaCorta(vm.hasta)}',
  };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VentasHoyViewModel>();
    final web = FormaGip.esWeb(context);
    final selector = SelectorFiltro<PeriodoVentas>(
      prefijoClave: 'ventas_periodo',
      elegido: vm.periodo,
      onElegir: (p) => p == PeriodoVentas.fechas
          ? _elegirFechas(context, vm)
          : vm.elegirPeriodo(p),
      opciones: const [
        (valor: PeriodoVentas.hoy, etiqueta: 'Hoy'),
        (valor: PeriodoVentas.ayer, etiqueta: 'Ayer'),
        (valor: PeriodoVentas.fechas, etiqueta: 'Fechas'),
      ],
    );
    final anuladas = vm.ventas.where((v) => v.isAnulada()).length;
    final vigentes = vm.ventas.length - anuladas;
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
                  titulo: _titulo(vm),
                  seccion: 'Caja',
                  miga: 'Ventas de hoy',
                  onVolver: () => _volver(context),
                  contexto: vm.cargando || vm.ventas.isEmpty
                      ? null
                      : '$vigentes ${vigentes == 1 ? 'venta' : 'ventas'}'
                            '${anuladas > 0 ? ' · $anuladas anulada${anuladas == 1 ? '' : 's'}' : ''}',
                  accion: web ? selector : null,
                ),
                if (!web) ...[const SizedBox(height: 12), selector],
                SizedBox(height: web ? 24 : 16),
                if (vm.aviso != null) ...[
                  MensajeResultado(
                    key: const Key('ventas_aviso'),
                    texto: vm.aviso!,
                    esError: false,
                  ),
                  const SizedBox(height: 16),
                ],
                if (vm.error != null) ...[
                  MensajeResultado(
                    key: const Key('ventas_error'),
                    texto: vm.error!,
                    esError: true,
                  ),
                  const SizedBox(height: 16),
                ],
                if (vm.cargando && vm.ventas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (vm.ventas.isEmpty)
                  _SinVentas(esHoy: vm.periodo == PeriodoVentas.hoy)
                else if (web)
                  _TablaVentas(
                    vm: vm,
                    conFecha: vm.periodo != PeriodoVentas.hoy,
                    onAnular: (v) => _anular(context, vm, v),
                  )
                else
                  _ListaVentas(
                    vm: vm,
                    conFecha: vm.periodo != PeriodoVentas.hoy,
                    onAnular: (v) => _anular(context, vm, v),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "10:42 a. m." o, si el periodo tiene más de un día, "14 nov. 10:42 a. m.".
String _cuando(DateTime fecha, bool conFecha) =>
    conFecha ? '${fechaCorta(fecha)} ${horaDe(fecha)}' : horaDe(fecha);

String _productosDe(VentasHoyViewModel vm, Venta venta) {
  final nombres = vm.nombresDe(venta);
  return nombres.isEmpty ? '—' : nombres.join(', ');
}

class _SinVentas extends StatelessWidget {
  const _SinVentas({required this.esHoy});

  final bool esHoy;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return TarjetaGip(
      key: const Key('ventas_vacio'),
      padding: const EdgeInsets.all(24),
      child: Text(
        esHoy ? 'Todavía no hay ventas hoy.' : 'No hay ventas en este periodo.',
        style: tema.textTheme.bodyLarge?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Tabla de la web: hora, productos, pago, total y la acción.
class _TablaVentas extends StatelessWidget {
  const _TablaVentas({
    required this.vm,
    required this.conFecha,
    required this.onAnular,
  });

  final VentasHoyViewModel vm;
  final bool conFecha;
  final void Function(Venta) onAnular;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final secundario = tema.textTheme.labelMedium;
    return TarjetaGip(
      key: const Key('ventas_tabla'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: conFecha ? 150 : 110,
                  child: Text('Hora', style: secundario),
                ),
                Expanded(child: Text('Productos', style: secundario)),
                SizedBox(width: 150, child: Text('Pago', style: secundario)),
                SizedBox(
                  width: 120,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.end,
                    style: secundario,
                  ),
                ),
                const SizedBox(width: 130),
              ],
            ),
          ),
          for (final venta in vm.ventas) _filaDe(context, venta),
        ],
      ),
    );
  }

  Widget _filaDe(BuildContext context, Venta venta) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final anulada = venta.isAnulada();
    final apagado = anulada ? esquema.onSurfaceVariant : null;
    return Container(
      key: Key('venta_${venta.getId()}'),
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: esquema.outlineVariant)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: conFecha ? 150 : 110,
            child: Text(
              _cuando(venta.getFecha(), conFecha),
              style: tema.textTheme.bodyMedium?.copyWith(color: apagado),
            ),
          ),
          Expanded(
            child: Text(
              _productosDe(vm, venta),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.bodyLarge?.copyWith(color: apagado),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              VentasHoyViewModel.pagoDe(venta),
              style: tema.textTheme.bodyMedium?.copyWith(color: apagado),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              pesos(venta.getTotal()),
              textAlign: TextAlign.end,
              style: tema.textTheme.bodyLarge?.cifrasTabulares.copyWith(
                color: apagado,
                decoration: anulada ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Align(
              alignment: Alignment.centerRight,
              child: anulada
                  ? const PildoraEstado('Anulada', tono: TonoEstado.neutro)
                  : BotonDestructivo(
                      key: Key('anular_${venta.getId()}'),
                      texto: 'Anular',
                      alto: 44,
                      onPressed: vm.anulando ? null : () => onAnular(venta),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista del móvil: una fila por venta, que se toca para anular (`Anular`).
class _ListaVentas extends StatelessWidget {
  const _ListaVentas({
    required this.vm,
    required this.conFecha,
    required this.onAnular,
  });

  final VentasHoyViewModel vm;
  final bool conFecha;
  final void Function(Venta) onAnular;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return TarjetaGip(
      key: const Key('ventas_lista'),
      child: Column(
        children: [
          for (var i = 0; i < vm.ventas.length; i++)
            _fila(tema, esquema, vm.ventas[i], i == 0),
        ],
      ),
    );
  }

  Widget _fila(ThemeData tema, ColorScheme esquema, Venta venta, bool primera) {
    final anulada = venta.isAnulada();
    final apagado = anulada ? esquema.onSurfaceVariant : null;
    final productos = vm.nombresDe(venta).length;
    return InkWell(
      key: Key('venta_${venta.getId()}'),
      onTap: anulada || vm.anulando ? null : () => onAnular(venta),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: primera
            ? null
            : BoxDecoration(
                border: Border(top: BorderSide(color: esquema.outlineVariant)),
              ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_cuando(venta.getFecha(), conFecha)}'
                    '${productos > 0 ? ' · $productos ${productos == 1 ? 'producto' : 'productos'}' : ''}',
                    style: tema.textTheme.titleMedium?.copyWith(color: apagado),
                  ),
                  Text(
                    VentasHoyViewModel.pagoDe(venta),
                    style: tema.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  pesos(venta.getTotal()),
                  style: tema.textTheme.titleMedium?.cifrasTabulares.copyWith(
                    color: apagado,
                    decoration: anulada ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (anulada) ...[
                  const SizedBox(height: 4),
                  const PildoraEstado('Anulada', tono: TonoEstado.neutro),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
