import 'package:flutter/material.dart';
import 'package:gip/business/entidades/info_tienda/formato_exportacion.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_fecha.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/mensaje_resultado.dart';
import 'package:gip/presentation/comun/nota_info.dart';
import 'package:gip/presentation/comun/opcion_con_icono.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/negocio/exportar_view_model.dart';
import 'package:gip/presentation/negocio/rutas_negocio.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Exportar datos (CUS-16), según los mockups `mExportar` y
/// `wExportar` con los componentes del rediseño. El propietario elige el
/// periodo de las ventas y el formato (Excel o CSV) y el sistema entrega el
/// archivo con inventario, ventas y fiados.
///
/// No se muestran el tamaño del archivo ni los botones "Compartir" y
/// "Descargar" de después de exportar: el exportador entrega el archivo al
/// terminar y el caso de uso solo devuelve su nombre (DI-41). Tampoco el
/// historial "Archivos generados" ni "movimientos de inventario": no se
/// guardan ni se exportan.
class ExportarView extends StatelessWidget {
  const ExportarView({super.key});

  static const notaPeriodo =
      'Si el periodo no es válido (por ejemplo, “hasta” antes de “desde”), se '
      'avisa antes de exportar.';

  void _volver(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(rutaPrincipalNegocio);
    }
  }

  Future<void> _elegirDia(
    BuildContext context,
    ExportarViewModel vm, {
    required DateTime inicial,
    required ValueChanged<DateTime> alElegir,
  }) async {
    final elegido = await showDatePicker(
      context: context,
      initialDate: inicial.isAfter(vm.hoy) ? vm.hoy : inicial,
      firstDate: DateTime(2020),
      lastDate: vm.hoy,
    );
    if (elegido != null) alElegir(elegido);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExportarViewModel>();
    final web = FormaGip.esWeb(context);

    final formulario = _Formulario(
      vm: vm,
      web: web,
      onDesde: () =>
          _elegirDia(context, vm, inicial: vm.desde, alElegir: vm.elegirDesde),
      onHasta: () => _elegirDia(
        context,
        vm,
        inicial: vm.ultimoDia,
        alElegir: vm.elegirHasta,
      ),
    );
    final resultado = _Resultado(vm: vm);

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: web ? 1240 : 880),
            child: ListView(
              padding: web
                  ? const EdgeInsets.fromLTRB(44, 32, 44, 48)
                  : const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                EncabezadoPantalla(
                  titulo: web ? 'Exportar datos del negocio' : 'Exportar datos',
                  miga: 'Exportar datos',
                  seccion: 'Negocio',
                  contexto: web
                      ? 'Lleve su información a otro lado cuando quiera.'
                      : 'Lleve su información a otro lado cuando quiera: '
                            'inventario, ventas y fiados.',
                  onVolver: () => _volver(context),
                ),
                SizedBox(height: web ? 24 : 18),
                if (web)
                  _ColumnasWeb(
                    formulario: TarjetaGip(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          formulario,
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _BotonExportar(vm: vm, expandido: false),
                          ),
                        ],
                      ),
                    ),
                    lateral: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        resultado,
                        if (vm.mensajeListo != null || vm.error != null)
                          const SizedBox(height: 14),
                        const NotaInfo(
                          key: Key('exportar_nota'),
                          texto: notaPeriodo,
                        ),
                      ],
                    ),
                  )
                else ...[
                  // El resultado va arriba: con el botón fijo abajo y el
                  // formulario largo, abajo no se vería sin desplazarse.
                  if (vm.mensajeListo != null || vm.error != null) ...[
                    resultado,
                    const SizedBox(height: 16),
                  ],
                  formulario,
                ],
              ],
            ),
          ),
        ),
      ),
      // En el móvil el botón va fijo abajo (mockup `mExportar`).
      bottomNavigationBar: web
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: _BotonExportar(vm: vm, expandido: true),
                ),
              ),
            ),
    );
  }
}

/// El formulario a la izquierda y lo que dejó el último intento a la derecha;
/// si no caben, abajo.
class _ColumnasWeb extends StatelessWidget {
  const _ColumnasWeb({required this.formulario, required this.lateral});

  final Widget formulario;
  final Widget lateral;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, restricciones) {
      if (restricciones.maxWidth < 520 + 24 + 340) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [formulario, const SizedBox(height: 24), lateral],
        );
      }
      final anchoLateral = (restricciones.maxWidth * 0.34).clamp(340.0, 420.0);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: formulario),
          const SizedBox(width: 24),
          SizedBox(width: anchoLateral, child: lateral),
        ],
      );
    },
  );
}

/// Desde, Hasta, formato y lo que incluye el archivo.
class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.vm,
    required this.web,
    required this.onDesde,
    required this.onHasta,
  });

  final ExportarViewModel vm;
  final bool web;
  final VoidCallback onDesde;
  final VoidCallback onHasta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final bloqueado = vm.exportando;
    final opciones = [
      OpcionConIcono(
        key: const Key('exportar_formato_excel'),
        icono: Icons.table_chart_outlined,
        titulo: 'Excel',
        descripcion: '.xlsx · para abrir y sumar',
        elegida: vm.formato == FormatoExportacion.excel,
        onTap: bloqueado
            ? null
            : () => vm.elegirFormato(FormatoExportacion.excel),
      ),
      OpcionConIcono(
        key: const Key('exportar_formato_csv'),
        icono: Icons.description_outlined,
        titulo: 'CSV',
        descripcion: 'para otro programa',
        elegida: vm.formato == FormatoExportacion.csv,
        onTap: bloqueado
            ? null
            : () => vm.elegirFormato(FormatoExportacion.csv),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampoFecha(
                key: const Key('exportar_desde'),
                etiqueta: 'Desde',
                fecha: vm.desde,
                onTap: bloqueado ? null : onDesde,
                error: vm.errorPeriodo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CampoFecha(
                key: const Key('exportar_hasta'),
                etiqueta: 'Hasta',
                fecha: vm.ultimoDia,
                onTap: bloqueado ? null : onHasta,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Formato', style: tema.textTheme.labelMedium),
        const SizedBox(height: 8),
        // En 360 px las dos opciones caben lado a lado con su descripción en
        // dos líneas; si no caben, una debajo de la otra.
        LayoutBuilder(
          builder: (context, restricciones) {
            if (restricciones.maxWidth < 320) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  opciones[0],
                  const SizedBox(height: 10),
                  opciones[1],
                ],
              );
            }
            // IntrinsicHeight: las dos opciones miden lo mismo aunque una
            // descripción ocupe más líneas.
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: opciones[0]),
                  const SizedBox(width: 12),
                  Expanded(child: opciones[1]),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const _Incluye(),
      ],
    );
  }
}

/// Lo que lleva el archivo: tres tablas (CSV: tres archivos).
class _Incluye extends StatelessWidget {
  const _Incluye();

  static const _lineas = [
    'Inventario con su existencia',
    'Ventas del periodo y formas de pago',
    'Fiados y abonos',
  ];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return Column(
      key: const Key('exportar_incluye'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Incluye', style: tema.textTheme.titleSmall),
        const SizedBox(height: 10),
        for (final linea in _lineas)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check, size: 20, color: esquema.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(linea, style: tema.textTheme.bodyLarge)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Lo que dejó el último intento: el archivo entregado o el error.
class _Resultado extends StatelessWidget {
  const _Resultado({required this.vm});

  final ExportarViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.error case final error?) {
      return TarjetaAviso(
        key: const Key('exportar_error'),
        titulo: error,
        icono: error == ExportarViewModel.mensajeSoloPropietario
            ? Icons.lock_outline
            : Icons.warning_amber_rounded,
      );
    }
    if (vm.mensajeListo case final listo?) {
      return MensajeResultado(
        key: const Key('exportar_listo'),
        texto: listo,
        esError: false,
      );
    }
    return const SizedBox.shrink();
  }
}

class _BotonExportar extends StatelessWidget {
  const _BotonExportar({required this.vm, required this.expandido});

  final ExportarViewModel vm;
  final bool expandido;

  @override
  Widget build(BuildContext context) {
    final boton = BotonPrimario(
      key: const Key('exportar_boton'),
      texto: 'Exportar',
      icono: Icons.file_download_outlined,
      cargando: vm.exportando,
      onPressed: vm.puedeExportar ? vm.exportar : null,
    );
    return expandido ? boton : IntrinsicWidth(child: boton);
  }
}
