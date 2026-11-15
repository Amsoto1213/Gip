import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/nota_info.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/selector_filtro.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tarjeta_cifra.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/comun/tema/tipografia_gip.dart';
import 'package:gip/presentation/negocio/margen_view_model.dart';
import 'package:gip/presentation/negocio/rutas_negocio.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Ganancia por producto (CUS-09), según los mockups `mMargen` y
/// `wMargen` con los componentes del rediseño. Muestra la ganancia de cada
/// producto en el periodo elegido; el producto al que le falta el costo de
/// alguna venta sale como "incompleto" y su advertencia va en rojo.
///
/// No se muestran "Unidades", "Vendió", "de 128 productos" ni "Descargar
/// Excel": el caso de uso solo entrega la ganancia por producto (DI-28).
class MargenView extends StatelessWidget {
  const MargenView({super.key});

  static const _meses = [
    'ene.',
    'feb.',
    'mar.',
    'abr.',
    'may.',
    'jun.',
    'jul.',
    'ago.',
    'sep.',
    'oct.',
    'nov.',
    'dic.',
  ];

  static String _dia(DateTime f) => '${f.day} ${_meses[f.month - 1]}';

  /// "5 nov. – 11 nov.", o un solo día si el periodo es de un día.
  static String rango(DateTime desde, DateTime ultimo) =>
      desde == ultimo ? _dia(desde) : '${_dia(desde)} – ${_dia(ultimo)}';

  static String pesos(Decimal valor) => valor < Decimal.zero
      ? '-\$ ${mostrarPrecio(-valor)}'
      : '\$ ${mostrarPrecio(valor)}';

  void _volver(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(rutaPrincipalNegocio);
    }
  }

  Future<void> _elegirFechas(BuildContext context, MargenViewModel vm) async {
    final hoy = DateTime.now();
    final elegido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(hoy.year, hoy.month, hoy.day),
      initialDateRange: DateTimeRange(start: vm.desde, end: vm.ultimoDia),
    );
    if (elegido != null) await vm.elegirFechas(elegido.start, elegido.end);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MargenViewModel>();
    final web = FormaGip.esWeb(context);
    final encabezado = EncabezadoPantalla(
      titulo: 'Ganancia por producto',
      miga: 'Ganancia por producto',
      seccion: 'Negocio',
      contexto: 'Precio menos costo de lo vendido, sin contar ventas anuladas.',
      onVolver: () => _volver(context),
    );

    final List<Widget> cuerpo;
    if (vm.error case final error?) {
      cuerpo = [
        const SizedBox(height: 22),
        TarjetaAviso(
          key: const Key('margen_error'),
          titulo: error,
          icono: error == MargenViewModel.mensajeSoloPropietario
              ? Icons.lock_outline
              : Icons.warning_amber_rounded,
        ),
      ];
    } else {
      cuerpo = [
        const SizedBox(height: 22),
        _Periodos(vm: vm, onFechas: () => _elegirFechas(context, vm)),
        const SizedBox(height: 18),
        if (vm.cargando && vm.filas.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _Cifras(vm: vm, web: web),
          const SizedBox(height: 18),
          if (vm.filas.isEmpty)
            const NotaInfo(
              key: Key('margen_sin_ventas'),
              texto: MargenViewModel.mensajeSinVentas,
            )
          else
            _Lista(vm: vm),
          if (vm.productosSinCosto > 0) ...[
            const SizedBox(height: 18),
            const TarjetaAviso(
              key: Key('margen_aviso_sin_costo'),
              titulo: '“Sin costo” = falta el costo de compra',
              texto:
                  'La ganancia de ese producto queda incompleta y no está en '
                  'el total. Regístrela en la próxima entrada de mercancía.',
            ),
          ],
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
                children: [encabezado, ...cuerpo],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hoy, Semana, Mes y un rango de fechas.
class _Periodos extends StatelessWidget {
  const _Periodos({required this.vm, required this.onFechas});

  final MargenViewModel vm;
  final VoidCallback onFechas;

  @override
  Widget build(BuildContext context) {
    final conRango = vm.periodo == PeriodoMargen.fechas;
    return SelectorFiltro<PeriodoMargen>(
      prefijoClave: 'margen_periodo',
      elegido: vm.periodo,
      onElegir: (p) {
        if (p == PeriodoMargen.fechas) {
          onFechas();
        } else {
          vm.elegirPeriodo(p);
        }
      },
      opciones: [
        (valor: PeriodoMargen.hoy, etiqueta: 'Hoy'),
        (valor: PeriodoMargen.semana, etiqueta: 'Semana'),
        (valor: PeriodoMargen.mes, etiqueta: 'Mes'),
        (
          valor: PeriodoMargen.fechas,
          etiqueta: conRango
              ? MargenView.rango(vm.desde, vm.ultimoDia)
              : 'Fechas',
        ),
      ],
    );
  }
}

/// Ganancia total, productos con ventas y productos sin costo.
class _Cifras extends StatelessWidget {
  const _Cifras({required this.vm, required this.web});

  final MargenViewModel vm;
  final bool web;

  @override
  Widget build(BuildContext context) {
    final periodo = MargenView.rango(vm.desde, vm.ultimoDia);
    final tarjetas = [
      TarjetaCifra(
        etiqueta: 'Ganancia del periodo',
        valor: MargenView.pesos(vm.gananciaTotal),
        valorKey: const Key('margen_total'),
        detalle: vm.productosSinCosto > 0
            ? '$periodo · sin los incompletos'
            : periodo,
      ),
      TarjetaCifra(
        etiqueta: 'Productos con ventas',
        valor: '${vm.productosConVentas}',
        valorKey: const Key('margen_con_ventas'),
      ),
      TarjetaCifra(
        etiqueta: 'Sin costo registrado',
        valor: '${vm.productosSinCosto}',
        valorKey: const Key('margen_sin_costo'),
        detalle: 'ganancia incompleta',
        enRojo: vm.productosSinCosto > 0,
      ),
    ];
    Widget fila(List<Widget> hijos) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, t) in hijos.indexed) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: t),
          ],
        ],
      ),
    );
    if (web) return fila(tarjetas);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tarjetas.first,
        const SizedBox(height: 12),
        fila(tarjetas.sublist(1)),
      ],
    );
  }
}

/// Un producto por fila con su ganancia y una barra proporcional a la mayor.
class _Lista extends StatelessWidget {
  const _Lista({required this.vm});

  final MargenViewModel vm;

  @override
  Widget build(BuildContext context) {
    final extra = Theme.of(context).extension<ColoresExtraGip>()!;
    return TarjetaGip(
      key: const Key('margen_lista'),
      child: Column(
        children: [
          for (final (i, fila) in vm.filas.indexed) ...[
            if (i > 0) Divider(height: 1, color: extra.separador),
            _FilaProducto(fila: fila, mayor: vm.mayorGanancia),
          ],
        ],
      ),
    );
  }
}

class _FilaProducto extends StatelessWidget {
  const _FilaProducto({required this.fila, required this.mayor});

  final FilaMargen fila;
  final Decimal mayor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final extra = tema.extension<ColoresExtraGip>()!;
    final margen = fila.margen;
    final proporcion = margen == null || mayor <= Decimal.zero
        ? 0.0
        : (margen / mayor).toDouble().clamp(0.0, 1.0);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    fila.producto.getNombre(),
                    style: tema.textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 12),
                if (margen == null)
                  const PildoraEstado('Sin costo', tono: TonoEstado.error)
                else
                  Text(
                    MargenView.pesos(margen),
                    style: tema.textTheme.titleSmall
                        ?.copyWith(
                          color: margen < Decimal.zero ? esquema.error : null,
                        )
                        .cifrasTabulares,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(FormaGip.radioChip),
              child: SizedBox(
                height: 8,
                child: margen == null
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            FormaGip.radioChip,
                          ),
                          border: Border.all(color: esquema.error),
                        ),
                      )
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: ColoredBox(color: extra.separador),
                          ),
                          FractionallySizedBox(
                            widthFactor: proporcion,
                            child: ColoredBox(color: esquema.primary),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
