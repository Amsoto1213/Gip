import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_caja/rotacion.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/nota_info.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/selector_filtro.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/negocio/margen_view.dart';
import 'package:gip/presentation/negocio/rotacion_view_model.dart';
import 'package:gip/presentation/negocio/rutas_negocio.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Rotación de productos (CUS-12), según los mockups `mRotacion` y
/// `wRotacion` con los componentes del rediseño. Reparte los productos de la
/// tienda en tres grupos (Alta, Media y Baja) según lo que vendieron en el
/// periodo. En el móvil se ve un grupo a la vez; en la web, los tres.
///
/// No se muestran las unidades de cada producto ni "Descargar Excel": el caso
/// de uso solo entrega el grupo de cada producto (DI-40).
class RotacionView extends StatelessWidget {
  const RotacionView({super.key});

  static const _nombres = {
    Rotacion.alta: 'Alta',
    Rotacion.media: 'Media',
    Rotacion.baja: 'Baja',
  };

  static const _titulos = {
    Rotacion.alta: 'Se vende mucho',
    Rotacion.media: 'Se vende regular',
    Rotacion.baja: 'Se vende poco',
  };

  static const _tercios = {
    Rotacion.alta: 'Tercio de arriba',
    Rotacion.media: 'Tercio del medio',
    Rotacion.baja: 'Tercio de abajo',
  };

  static const _tonos = {
    Rotacion.alta: TonoEstado.bien,
    Rotacion.media: TonoEstado.neutro,
    Rotacion.baja: TonoEstado.error,
  };

  static const notaMovil =
      'Se ordenan los productos por unidades vendidas y se parten en tres '
      'grupos iguales. Los que no vendieron nada quedan en Baja.';

  static const notaWeb =
      'Los productos que no vendieron nada en el periodo también aparecen, en '
      'el grupo Baja.';

  void _volver(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(rutaPrincipalNegocio);
    }
  }

  Future<void> _elegirFechas(BuildContext context, RotacionViewModel vm) async {
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
    final vm = context.watch<RotacionViewModel>();
    final web = FormaGip.esWeb(context);
    final encabezado = EncabezadoPantalla(
      titulo: 'Rotación de productos',
      miga: 'Rotación',
      seccion: 'Negocio',
      contexto: web
          ? 'Se ordenan por unidades vendidas y se parten en tres grupos '
                'iguales.'
          : null,
      onVolver: () => _volver(context),
    );

    final List<Widget> cuerpo;
    if (vm.error case final error?) {
      cuerpo = [
        const SizedBox(height: 22),
        TarjetaAviso(
          key: const Key('rotacion_error'),
          titulo: error,
          icono: error == RotacionViewModel.mensajeSoloPropietario
              ? Icons.lock_outline
              : Icons.warning_amber_rounded,
        ),
      ];
    } else {
      cuerpo = [
        const SizedBox(height: 22),
        _Periodos(vm: vm, web: web, onFechas: () => _elegirFechas(context, vm)),
        const SizedBox(height: 18),
        if (vm.cargando && vm.totalProductos == 0)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (vm.totalProductos == 0)
          const NotaInfo(
            key: Key('rotacion_sin_productos'),
            texto: RotacionViewModel.mensajeSinProductos,
          )
        else ...[
          if (web) _Columnas(vm: vm) else _UnGrupo(vm: vm),
          const SizedBox(height: 18),
          NotaInfo(
            key: const Key('rotacion_nota'),
            texto: web ? notaWeb : notaMovil,
          ),
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

/// 30 días, Este mes y un rango de fechas.
class _Periodos extends StatelessWidget {
  const _Periodos({
    required this.vm,
    required this.web,
    required this.onFechas,
  });

  final RotacionViewModel vm;
  final bool web;
  final VoidCallback onFechas;

  @override
  Widget build(BuildContext context) {
    final conRango = vm.periodo == PeriodoRotacion.fechas;
    return SelectorFiltro<PeriodoRotacion>(
      prefijoClave: 'rotacion_periodo',
      elegido: vm.periodo,
      onElegir: (p) {
        if (p == PeriodoRotacion.fechas) {
          onFechas();
        } else {
          vm.elegirPeriodo(p);
        }
      },
      opciones: [
        (
          valor: PeriodoRotacion.dias30,
          etiqueta: web ? 'Últimos 30 días' : '30 días',
        ),
        (valor: PeriodoRotacion.mes, etiqueta: 'Este mes'),
        (
          valor: PeriodoRotacion.fechas,
          etiqueta: conRango
              ? MargenView.rango(vm.desde, vm.ultimoDia)
              : 'Fechas',
        ),
      ],
    );
  }
}

/// Móvil: selector Alta / Media / Baja y la tarjeta del grupo elegido.
class _UnGrupo extends StatelessWidget {
  const _UnGrupo({required this.vm});

  final RotacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectorFiltro<Rotacion>(
          prefijoClave: 'rotacion_grupo',
          estilo: EstiloFiltro.pestanas,
          elegido: vm.grupo,
          onElegir: vm.elegirGrupo,
          opciones: [
            for (final g in Rotacion.values)
              (
                valor: g,
                etiqueta: '${RotacionView._nombres[g]} · ${vm.cantidadDe(g)}',
              ),
          ],
        ),
        const SizedBox(height: 14),
        _TarjetaGrupo(vm: vm, grupo: vm.grupo, movil: true),
      ],
    );
  }
}

/// Web: los tres grupos lado a lado.
class _Columnas extends StatelessWidget {
  const _Columnas({required this.vm});

  final RotacionViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, g) in Rotacion.values.indexed) ...[
          if (i > 0) const SizedBox(width: 22),
          Expanded(
            child: _TarjetaGrupo(vm: vm, grupo: g, movil: false),
          ),
        ],
      ],
    );
  }
}

/// Un grupo: encabezado con su píldora y un producto por fila.
class _TarjetaGrupo extends StatelessWidget {
  const _TarjetaGrupo({
    required this.vm,
    required this.grupo,
    required this.movil,
  });

  final RotacionViewModel vm;
  final Rotacion grupo;
  final bool movil;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final productos = vm.productosDe(grupo);
    final clave = grupo.name;
    return TarjetaGip(
      key: Key('rotacion_lista_$clave'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    movil
                        ? RotacionView._titulos[grupo]!
                        : RotacionView._nombres[grupo]!,
                    style: tema.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 12),
                PildoraEstado(
                  movil
                      ? RotacionView._tercios[grupo]!
                      : '${productos.length} '
                            '${productos.length == 1 ? 'producto' : 'productos'}',
                  tono: RotacionView._tonos[grupo]!,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: extra.separador),
          if (productos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Ningún producto en este grupo',
                key: Key('rotacion_vacio_$clave'),
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final (i, producto) in productos.indexed) ...[
              if (i > 0) Divider(height: 1, color: extra.separador),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      producto.getNombre(),
                      style: tema.textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}
