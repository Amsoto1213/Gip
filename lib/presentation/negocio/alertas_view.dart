import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/alerta_reabastecimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/venta_perdida.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/nota_info.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/selector_filtro.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/negocio/alertas_view_model.dart';
import 'package:gip/presentation/negocio/rutas_negocio.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Alertas de surtido (CUS-05), según los mockups `Alertas` y
/// `wAlertas` con los componentes del rediseño. Muestra las alertas que
/// calculó CUS-24 hoy, cada una con su sustento (Hay, Vende al día, Se fueron
/// sin comprar y Alcanza para), y en otra pestaña las ventas perdidas de los
/// últimos 30 días. Las advertencias van en rojo.
///
/// No se muestran "Urgente" ni "Pronto" (el diseño no define esos cortes), la
/// hora del cálculo, "Datos de N días", la barra de "Alcanza para" ni "Armar
/// lista de pedido": el caso de uso no los entrega (DI-25).
class AlertasView extends StatelessWidget {
  const AlertasView({super.key});

  static const _contexto =
      'Calculadas hoy. Son sugerencias: usted decide qué comprar.';

  /// Desde este ancho la explicación va a la derecha de la tabla.
  static const _anchoDosColumnas = 1100.0;

  void _volver(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(rutaPrincipalNegocio);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AlertasViewModel>();
    final web = FormaGip.esWeb(context);
    final encabezado = EncabezadoPantalla(
      titulo: 'Alertas de surtido',
      miga: 'Alertas de surtido',
      seccion: 'Negocio',
      contexto: _contexto,
      onVolver: () => _volver(context),
    );

    final List<Widget> cuerpo;
    if (vm.cargando && vm.alertas.isEmpty && vm.error == null) {
      cuerpo = const [
        SizedBox(height: 48),
        Center(child: CircularProgressIndicator()),
      ];
    } else if (vm.error case final error?) {
      cuerpo = [
        const SizedBox(height: 22),
        TarjetaAviso(
          key: const Key('alertas_error'),
          titulo: error,
          icono: error == AlertasViewModel.mensajeSoloPropietario
              ? Icons.lock_outline
              : Icons.warning_amber_rounded,
        ),
      ];
    } else {
      final pestanas = SelectorFiltro<PestanaAlertas>(
        prefijoClave: 'alertas_pestana',
        estilo: EstiloFiltro.pestanas,
        elegido: vm.pestana,
        onElegir: vm.elegirPestana,
        opciones: [
          (
            valor: PestanaAlertas.porSurtir,
            etiqueta: 'Por surtir · ${vm.alertas.length}',
          ),
          (
            valor: PestanaAlertas.ventasPerdidas,
            etiqueta: 'Ventas perdidas · ${vm.ventasPerdidas.length}',
          ),
        ],
      );
      final contenido = switch (vm.pestana) {
        PestanaAlertas.porSurtir => _PorSurtir(vm: vm, web: web),
        PestanaAlertas.ventasPerdidas => _VentasPerdidas(vm: vm),
      };
      cuerpo = [
        const SizedBox(height: 22),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: pestanas,
          ),
        ),
        const SizedBox(height: 22),
        if (web)
          LayoutBuilder(
            builder: (context, restricciones) {
              if (restricciones.maxWidth < _anchoDosColumnas) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    contenido,
                    const SizedBox(height: 22),
                    const _ComoLeerlas(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: contenido),
                  const SizedBox(width: 22),
                  const SizedBox(width: 420, child: _ComoLeerlas()),
                ],
              );
            },
          )
        else ...[
          contenido,
          if (vm.pestana == PestanaAlertas.porSurtir &&
              vm.hayProvisionales) ...[
            const SizedBox(height: 16),
            const _NotaProvisional(),
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

/// Explicación "Provisional = …" de los mockups.
class _NotaProvisional extends StatelessWidget {
  const _NotaProvisional();

  @override
  Widget build(BuildContext context) => const NotaInfo(
    key: Key('alertas_nota_provisional'),
    destacado: 'Provisional =',
    texto: 'lleva menos de 30 días de ventas; el cálculo puede cambiar.',
  );
}

/// Tarjeta "Cómo leerlas" de `wAlertas`.
class _ComoLeerlas extends StatelessWidget {
  const _ComoLeerlas();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estilo = tema.textTheme.bodyLarge?.copyWith(height: 1.55);
    const negrilla = TextStyle(fontWeight: FontWeight.w700);
    return TarjetaGip(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cómo leerlas', style: tema.textTheme.titleLarge),
          const SizedBox(height: 12),
          Text.rich(
            const TextSpan(
              children: [
                TextSpan(text: 'Cada alerta muestra los tres datos que la '),
                TextSpan(text: 'sostienen: '),
                TextSpan(text: 'lo que hay', style: negrilla),
                TextSpan(text: ', '),
                TextSpan(text: 'lo que vende al día', style: negrilla),
                TextSpan(text: ' y '),
                TextSpan(text: 'para cuántos días alcanza', style: negrilla),
                TextSpan(
                  text:
                      '. Las ventas perdidas se suman a lo que '
                      'vende.',
                ),
              ],
            ),
            style: estilo,
          ),
          const SizedBox(height: 18),
          const _NotaProvisional(),
        ],
      ),
    );
  }
}

/// Mensaje centrado dentro de una tarjeta, para una lista vacía.
class _Vacio extends StatelessWidget {
  const _Vacio({required this.mensaje, required this.icono, super.key});

  final String mensaje;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return TarjetaGip(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        children: [
          Icon(icono, size: 32, color: tema.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: tema.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _PorSurtir extends StatelessWidget {
  const _PorSurtir({required this.vm, required this.web});

  final AlertasViewModel vm;
  final bool web;

  @override
  Widget build(BuildContext context) {
    if (vm.alertas.isEmpty) {
      return const _Vacio(
        key: Key('alertas_sin_alertas'),
        mensaje: AlertasViewModel.mensajeSinAlertas,
        icono: Icons.check_circle_outline,
      );
    }
    if (web) return _TablaAlertas(vm: vm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, alerta) in vm.alertas.indexed) ...[
          if (i > 0) const SizedBox(height: 12),
          _TarjetaAlerta(
            alerta: alerta,
            perdidas: vm.ventasPerdidasDe(alerta.getItem().getProducto()),
          ),
        ],
      ],
    );
  }
}

/// Columnas de la tabla web: Producto · Hay · Vende al día · Se fueron sin
/// comprar · Alcanza para.
abstract final class _Columnas {
  static const producto = 26;
  static const hay = 9;
  static const vende = 11;
  static const perdidas = 14;
  static const alcanza = 12;
  static const espacio = 16.0;
  static const relleno = EdgeInsets.symmetric(horizontal: 24, vertical: 14);
}

class _TablaAlertas extends StatelessWidget {
  const _TablaAlertas({required this.vm});

  final AlertasViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final estiloEncabezado = tema.textTheme.labelMedium?.copyWith(
      fontSize: 13,
      letterSpacing: 0.5,
      color: tema.colorScheme.onSurfaceVariant,
    );
    Text t(String texto, [TextAlign alineacion = TextAlign.end]) => Text(
      texto.toUpperCase(),
      style: estiloEncabezado,
      textAlign: alineacion,
    );
    return TarjetaGip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: extra.superficieSuave,
            child: Padding(
              padding: _Columnas.relleno,
              child: _FilaColumnas(
                producto: t('Producto', TextAlign.start),
                hay: t('Hay'),
                vende: t('Vende al día'),
                perdidas: t('Se fueron sin comprar'),
                alcanza: t('Alcanza para'),
              ),
            ),
          ),
          for (final alerta in vm.alertas)
            _FilaAlerta(
              alerta: alerta,
              perdidas: vm.ventasPerdidasDe(alerta.getItem().getProducto()),
            ),
        ],
      ),
    );
  }
}

class _FilaColumnas extends StatelessWidget {
  const _FilaColumnas({
    required this.producto,
    required this.hay,
    required this.vende,
    required this.perdidas,
    required this.alcanza,
  });

  final Widget producto;
  final Widget hay;
  final Widget vende;
  final Widget perdidas;
  final Widget alcanza;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(flex: _Columnas.producto, child: producto),
      const SizedBox(width: _Columnas.espacio),
      Expanded(flex: _Columnas.hay, child: hay),
      const SizedBox(width: _Columnas.espacio),
      Expanded(flex: _Columnas.vende, child: vende),
      const SizedBox(width: _Columnas.espacio),
      Expanded(flex: _Columnas.perdidas, child: perdidas),
      const SizedBox(width: _Columnas.espacio),
      Expanded(flex: _Columnas.alcanza, child: alcanza),
    ],
  );
}

class _FilaAlerta extends StatelessWidget {
  const _FilaAlerta({required this.alerta, required this.perdidas});

  final AlertaReabastecimiento alerta;
  final int perdidas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final extra = tema.extension<ColoresExtraGip>()!;
    final cifra = tema.textTheme.bodyLarge?.cifrasTabulares;
    Text n(String texto) => Text(texto, style: cifra, textAlign: TextAlign.end);
    return Container(
      key: Key('alerta_${alerta.getId()}'),
      constraints: const BoxConstraints(minHeight: 56),
      padding: _Columnas.relleno,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: extra.separador)),
      ),
      child: _FilaColumnas(
        producto: Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              alerta.getItem().getProducto().getNombre(),
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (alerta.isProvisional())
              const PildoraEstado('Provisional', tono: TonoEstado.informativo),
          ],
        ),
        hay: n(mostrarExistencia(alerta.getExistencia())),
        vende: n(mostrarConsumo(alerta.getConsumoPromedioDiario())),
        perdidas: n('$perdidas'),
        alcanza: Text(
          mostrarDias(alerta.getDiasCobertura()),
          textAlign: TextAlign.end,
          style: tema.textTheme.titleMedium?.cifrasTabulares.copyWith(
            fontWeight: FontWeight.w800,
            color: esquema.error,
          ),
        ),
      ),
    );
  }
}

/// Alerta en el móvil (`Alertas`): a la izquierda el bloque rojo con los días
/// que alcanza; a la derecha el producto y su sustento.
class _TarjetaAlerta extends StatelessWidget {
  const _TarjetaAlerta({required this.alerta, required this.perdidas});

  final AlertaReabastecimiento alerta;
  final int perdidas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final dias = alerta.getDiasCobertura();
    return TarjetaGip(
      key: Key('alerta_${alerta.getId()}'),
      radio: FormaGip.radioTarjetaMovil,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 84,
              color: esquema.errorContainer,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mostrarNumeroDias(dias),
                    style: tema.textTheme.headlineLarge?.cifrasTabulares
                        .copyWith(color: esquema.error),
                  ),
                  Text(
                    unidadDias(dias),
                    style: tema.textTheme.labelLarge?.copyWith(
                      color: esquema.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          alerta.getItem().getProducto().getNombre(),
                          style: tema.textTheme.titleLarge,
                        ),
                        if (alerta.isProvisional())
                          const PildoraEstado(
                            'Provisional',
                            tono: TonoEstado.informativo,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Dato(
                            'Hay',
                            mostrarExistencia(alerta.getExistencia()),
                          ),
                        ),
                        Expanded(
                          child: _Dato(
                            'Vende/día',
                            mostrarConsumo(alerta.getConsumoPromedioDiario()),
                          ),
                        ),
                        Expanded(
                          child: _Dato('No hubo', switch (perdidas) {
                            0 => '0',
                            1 => '1 vez',
                            _ => '$perdidas veces',
                          }),
                        ),
                      ],
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

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: tema.textTheme.bodyMedium?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          valor,
          style: tema.textTheme.titleMedium?.cifrasTabulares.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VentasPerdidas extends StatelessWidget {
  const _VentasPerdidas({required this.vm});

  final AlertasViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.ventasPerdidas.isEmpty) {
      return const _Vacio(
        key: Key('alertas_sin_ventas_perdidas'),
        mensaje: 'No hubo ventas perdidas en los últimos 30 días',
        icono: Icons.check_circle_outline,
      );
    }
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    return TarjetaGip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, venta) in vm.ventasPerdidas.indexed)
            Container(
              key: Key('venta_perdida_${venta.getId()}'),
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: extra.separador)),
              ),
              child: _FilaVentaPerdida(venta: venta),
            ),
        ],
      ),
    );
  }
}

class _FilaVentaPerdida extends StatelessWidget {
  const _FilaVentaPerdida({required this.venta});

  final VentaPerdida venta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final nombre = Text(
      venta.getProducto().getNombre(),
      style: tema.textTheme.titleMedium,
    );
    final fecha = Text(
      mostrarFechaHora(venta.getFecha()),
      style: tema.textTheme.bodyMedium?.cifrasTabulares.copyWith(
        color: tema.colorScheme.onSurfaceVariant,
      ),
    );
    if (!FormaGip.esWeb(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [nombre, const SizedBox(height: 2), fecha],
      );
    }
    return Row(
      children: [
        Expanded(child: nombre),
        const SizedBox(width: 12),
        fecha,
      ],
    );
  }
}

/// Existencia con miles con punto y decimales con coma ("1.250", "2,5").
@visibleForTesting
String mostrarExistencia(Decimal valor) => mostrarPrecio(valor);

/// Consumo con un decimal, como en los mockups ("2,3", "2,0").
@visibleForTesting
String mostrarConsumo(Decimal valor) =>
    valor.round(scale: 1).toStringAsFixed(1).replaceAll('.', ',');

/// Días de cobertura truncados a un decimal, sin ",0": 6,99 → "6,9" (nunca
/// llega al umbral por redondear), 2 → "2".
@visibleForTesting
String mostrarNumeroDias(Decimal dias) {
  final truncado = dias < Decimal.zero ? Decimal.zero : dias.truncate(scale: 1);
  return truncado.isInteger
      ? truncado.toBigInt().toString()
      : truncado.toStringAsFixed(1).replaceAll('.', ',');
}

/// "día" solo cuando es exactamente uno.
@visibleForTesting
String unidadDias(Decimal dias) =>
    mostrarNumeroDias(dias) == '1' ? 'día' : 'días';

/// "N día(s)" para la columna Alcanza para.
@visibleForTesting
String mostrarDias(Decimal dias) =>
    '${mostrarNumeroDias(dias)} ${unidadDias(dias)}';

const _meses = [
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

/// Fecha y hora local: "3 nov. · 10:05 a. m.".
@visibleForTesting
String mostrarFechaHora(DateTime fecha) {
  final f = fecha.toLocal();
  final hora12 = f.hour % 12 == 0 ? 12 : f.hour % 12;
  final minutos = f.minute.toString().padLeft(2, '0');
  final sufijo = f.hour < 12 ? 'a. m.' : 'p. m.';
  return '${f.day} ${_meses[f.month - 1]} · $hora12:$minutos $sufijo';
}
