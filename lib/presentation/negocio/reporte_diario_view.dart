import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_caja/reporte_diario.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/nota_info.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tarjeta_cifra.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/comun/tema/tipografia_gip.dart';
import 'package:gip/presentation/negocio/margen_view.dart';
import 'package:gip/presentation/negocio/reporte_diario_view_model.dart';
import 'package:gip/presentation/negocio/rutas_negocio.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Reporte del día (CUS-10), según los mockups `mReporte` y `Reporte`
/// con los componentes del rediseño. Muestra lo que entrega el reporte: lo
/// vendido, los gastos, la ganancia, el dinero de Nequi, las entradas de
/// mercancía, los fiados y los retiros personales aparte (RF-10).
///
/// "Incompleto" (falta un costo) va en rojo; "parcial" (cambios sin subir al
/// servidor) es solo información, en azul (DI-29). No se muestran el número de
/// ventas, "Le costó lo vendido", el efectivo, el cierre de caja, la lista de
/// productos, "Imprimir" ni "Descargar Excel": el caso de uso no los entrega.
class ReporteDiarioView extends StatelessWidget {
  const ReporteDiarioView({super.key});

  static const _dias = ['lun.', 'mar.', 'mié.', 'jue.', 'vie.', 'sáb.', 'dom.'];
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

  /// "Hoy, mié. 11 nov." o "mar. 10 nov.".
  static String etiquetaFecha(DateTime f, {required bool esHoy}) =>
      '${esHoy ? 'Hoy, ' : ''}${_dias[f.weekday - 1]} ${f.day} '
      '${_meses[f.month - 1]}';

  static const textoParcial =
      'Hay cambios de este equipo sin subir al servidor; si la tienda usa '
      'varios equipos, puede faltar información';

  void _volver(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(rutaPrincipalNegocio);
    }
  }

  Future<void> _elegirFecha(
    BuildContext context,
    ReporteDiarioViewModel vm,
  ) async {
    final hoy = DateTime.now();
    final elegido = await showDatePicker(
      context: context,
      initialDate: vm.fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(hoy.year, hoy.month, hoy.day),
    );
    if (elegido != null) await vm.elegirFecha(elegido);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReporteDiarioViewModel>();
    final web = FormaGip.esWeb(context);
    final reporte = vm.reporte;
    final encabezado = EncabezadoPantalla(
      titulo: 'Reporte del día',
      miga: 'Reporte del día',
      seccion: 'Negocio',
      contexto: 'Lo que vendió, gastó y ganó el negocio en el día.',
      onVolver: () => _volver(context),
    );

    final List<Widget> cuerpo;
    if (vm.error case final error?) {
      cuerpo = [
        const SizedBox(height: 22),
        TarjetaAviso(
          key: const Key('reporte_error'),
          titulo: error,
          icono: error == ReporteDiarioViewModel.mensajeSoloPropietario
              ? Icons.lock_outline
              : Icons.warning_amber_rounded,
        ),
      ];
    } else {
      cuerpo = [
        const SizedBox(height: 22),
        _Fecha(vm: vm, onElegir: () => _elegirFecha(context, vm)),
        const SizedBox(height: 18),
        if (reporte == null)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          if (reporte.isIncompleto()) ...[
            const TarjetaAviso(
              key: Key('reporte_aviso_incompleto'),
              titulo: 'Falta el costo de algún producto vendido',
              texto:
                  'La ganancia es incompleta: no cuenta lo vendido sin costo. '
                  'Regístrelo en la próxima entrada de mercancía.',
            ),
            const SizedBox(height: 18),
          ],
          if (reporte.isParcial()) ...[
            const NotaInfo(
              key: Key('reporte_aviso_parcial'),
              texto: textoParcial,
            ),
            const SizedBox(height: 18),
          ],
          if (vm.sinMovimiento) ...[
            const NotaInfo(
              key: Key('reporte_sin_movimiento'),
              texto: 'No hay ventas, abonos ni entradas en este día',
            ),
            const SizedBox(height: 18),
          ],
          _Ganancia(reporte: reporte, esHoy: vm.esHoy, web: web),
          const SizedBox(height: 18),
          if (web)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _DineroDelDia(reporte: reporte)),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _Entradas(reporte: reporte),
                      const SizedBox(height: 18),
                      _Fiados(reporte: reporte),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            _DineroDelDia(reporte: reporte),
            const SizedBox(height: 18),
            _Entradas(reporte: reporte),
            const SizedBox(height: 18),
            _Fiados(reporte: reporte),
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

/// Día anterior, el día elegido (abre el calendario) y día siguiente.
class _Fecha extends StatelessWidget {
  const _Fecha({required this.vm, required this.onElegir});

  final ReporteDiarioViewModel vm;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BotonIconoSecundario(
          key: const Key('reporte_anterior'),
          icono: Icons.chevron_left,
          tooltip: 'Día anterior',
          onPressed: vm.irDiaAnterior,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: BotonSecundario(
            key: const Key('reporte_fecha'),
            texto: ReporteDiarioView.etiquetaFecha(vm.fecha, esHoy: vm.esHoy),
            icono: Icons.calendar_today_outlined,
            expandido: true,
            onPressed: onElegir,
          ),
        ),
        const SizedBox(width: 10),
        BotonIconoSecundario(
          key: const Key('reporte_siguiente'),
          icono: Icons.chevron_right,
          tooltip: 'Día siguiente',
          onPressed: vm.puedeAvanzar ? vm.irDiaSiguiente : null,
        ),
      ],
    );
  }
}

/// Vendió, gastos del negocio y ganancia; los retiros personales van aparte.
class _Ganancia extends StatelessWidget {
  const _Ganancia({
    required this.reporte,
    required this.esHoy,
    required this.web,
  });

  final ReporteDiario reporte;
  final bool esHoy;
  final bool web;

  @override
  Widget build(BuildContext context) {
    final incompleto = reporte.isIncompleto();
    final tarjetas = [
      TarjetaCifra(
        etiqueta: 'Vendió',
        valor: MargenView.pesos(reporte.getTotalVentas()),
        valorKey: const Key('reporte_ventas'),
      ),
      TarjetaCifra(
        etiqueta: 'Gastos del negocio',
        valor: MargenView.pesos(reporte.getGastosNegocio()),
        valorKey: const Key('reporte_gastos'),
      ),
      TarjetaCifra(
        etiqueta: 'Ganancia del negocio',
        valor: MargenView.pesos(reporte.getUtilidad()),
        valorKey: const Key('reporte_utilidad'),
        detalle: incompleto ? 'incompleta' : 'sin contar retiros personales',
        enRojo: incompleto || reporte.getUtilidad() < Decimal.zero,
      ),
    ];
    final retiros = reporte.getRetirosPersonales();
    return TarjetaGip(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              esHoy
                  ? '¿Cuánto ganó el negocio hoy?'
                  : '¿Cuánto ganó el negocio?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            if (web)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, t) in tarjetas.indexed) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: t),
                    ],
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, t) in tarjetas.indexed) ...[
                    if (i > 0) const SizedBox(height: 12),
                    t,
                  ],
                ],
              ),
            if (retiros > Decimal.zero) ...[
              const SizedBox(height: 14),
              NotaInfo(
                key: const Key('reporte_retiros'),
                destacado: 'Sacó para la casa: ${MargenView.pesos(retiros)}.',
                texto:
                    'Se anota aparte para que no se confunda con lo que gana '
                    'la tienda.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lo que llegó por Nequi, de ventas y de abonos (DA-63, DA-64).
class _DineroDelDia extends StatelessWidget {
  const _DineroDelDia({required this.reporte});

  final ReporteDiario reporte;

  @override
  Widget build(BuildContext context) => _Seccion(
    titulo: 'Dinero por Nequi',
    filas: [
      _FilaDato(
        'Ventas por Nequi',
        MargenView.pesos(reporte.getVentasNequi()),
        valorKey: const Key('reporte_ventas_nequi'),
      ),
      _FilaDato(
        'Abonos por Nequi',
        MargenView.pesos(reporte.getAbonosNequi()),
        valorKey: const Key('reporte_abonos_nequi'),
      ),
      _FilaDato(
        'Entró por Nequi',
        MargenView.pesos(reporte.calcularDineroNequi()),
        valorKey: const Key('reporte_nequi'),
        destacada: true,
      ),
    ],
  );
}

class _Entradas extends StatelessWidget {
  const _Entradas({required this.reporte});

  final ReporteDiario reporte;

  @override
  Widget build(BuildContext context) => _Seccion(
    titulo: 'Mercancía que entró',
    filas: [
      _FilaDato(
        'Total compras',
        MargenView.pesos(reporte.getTotalEntradas()),
        valorKey: const Key('reporte_entradas'),
        destacada: true,
      ),
    ],
  );
}

/// Lo que se fió y lo que abonaron en el día.
class _Fiados extends StatelessWidget {
  const _Fiados({required this.reporte});

  final ReporteDiario reporte;

  @override
  Widget build(BuildContext context) => TarjetaGip(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fiados del día',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TarjetaCifra(
                    etiqueta: 'Se fió',
                    valor: MargenView.pesos(reporte.getVentasFiadas()),
                    valorKey: const Key('reporte_fiado'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TarjetaCifra(
                    etiqueta: 'Abonaron',
                    valor: MargenView.pesos(reporte.getAbonosRecibidos()),
                    valorKey: const Key('reporte_abonos'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Tarjeta con título y filas de etiqueta y valor.
class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.filas});

  final String titulo;
  final List<_FilaDato> filas;

  @override
  Widget build(BuildContext context) {
    final extra = Theme.of(context).extension<ColoresExtraGip>()!;
    return TarjetaGip(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final (i, fila) in filas.indexed) ...[
              if (i > 0) Divider(height: 1, color: extra.separador),
              fila,
            ],
          ],
        ),
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  const _FilaDato(
    this.etiqueta,
    this.valor, {
    required this.valorKey,
    this.destacada = false,
  });

  final String etiqueta;
  final String valor;
  final Key valorKey;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: destacada ? texto.titleSmall : texto.bodyLarge,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            valor,
            key: valorKey,
            style: (destacada ? texto.titleSmall : texto.bodyLarge)
                ?.cifrasTabulares,
          ),
        ],
      ),
    );
  }
}
