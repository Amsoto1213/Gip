import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/barra_busqueda.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/icono_paquete.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/selector_filtro.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/surtido/conteo_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:gip/presentation/surtido/widgets_movimiento.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Conteo físico (CUS-04), según `docs/ui/rediseno/conteo-web.html`
/// y `conteo-movil.html`: avance "N de M contados", tarjeta roja con las
/// diferencias grandes, búsqueda, filtros y la lista con lo que dice el
/// sistema, el campo de lo contado, la diferencia y el estado de cada fila
/// (Cuadra, Se ajusta, Diferencia grande, error o Sin contar). Abajo, una
/// barra blanca solo con "Confirmar ajuste".
///
/// El número se corrige en el mismo campo: no hay "Volver a contar" ni
/// "Pausar". Tampoco el lector, "se guarda mientras avanza", quién empezó el
/// conteo, "Imprimir etiquetas QR" ni "Cambiar el límite": el caso de uso no
/// los entrega (DI-24).
class ConteoView extends StatefulWidget {
  const ConteoView({super.key});

  @override
  State<ConteoView> createState() => _ConteoViewState();
}

class _ConteoViewState extends State<ConteoView> {
  final _busqueda = TextEditingController();
  final _campos = _CamposConteo();
  ConteoViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<ConteoViewModel>();
    if (!identical(vm, _vm)) {
      _vm?.removeListener(_sincronizar);
      _vm = vm..addListener(_sincronizar);
    }
  }

  /// Lleva a cada campo el texto del view model cuando este lo cambia por su
  /// cuenta (un ajuste guardado deja la cantidad vacía). Corre fuera del
  /// redibujo, así que no mueve el cursor del campo en el que se escribe.
  void _sincronizar() {
    for (final fila in _vm!.todas) {
      _campos.sincronizar(fila);
    }
  }

  @override
  void dispose() {
    _vm?.removeListener(_sincronizar);
    _campos.dispose();
    _busqueda.dispose();
    super.dispose();
  }

  void _volver() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(rutaPrincipalSurtido);
    }
  }

  Future<void> _confirmar() async {
    FocusScope.of(context).unfocus();
    await context.read<ConteoViewModel>().confirmar();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ConteoViewModel>();
    final web = FormaGip.esWeb(context);
    final encabezado = EncabezadoPantalla(
      titulo: 'Conteo físico',
      miga: 'Conteo físico',
      seccion: 'Surtido',
      contexto: web
          ? 'Escriba cuánto hay en el estante. Al confirmar, la existencia '
                'queda igual a lo contado.'
          : null,
      onVolver: _volver,
    );
    final boton = BotonPrimario(
      key: const Key('conteo_confirmar'),
      texto: !web
          ? 'Confirmar ajuste de ${vm.contados}'
          : vm.contados == 1
          ? 'Confirmar ajuste de 1 producto'
          : 'Confirmar ajuste de ${vm.contados} productos',
      icono: Icons.check,
      cargando: vm.registrando,
      onPressed: vm.puedeConfirmar ? _confirmar : null,
    );
    final mensajes = MensajesMovimiento(error: vm.error, aviso: vm.aviso);
    final busqueda = BarraBusqueda(
      pista: web ? 'Buscar producto por nombre' : 'Buscar producto',
      controlador: _busqueda,
      campoKey: const Key('conteo_buscar'),
      onChanged: vm.buscar,
    );

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: web ? 1240 : 880),
            child: web
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(44, 32, 44, 48),
                    children: [
                      encabezado,
                      const SizedBox(height: 22),
                      _AvanceWeb(vm: vm),
                      const SizedBox(height: 22),
                      TarjetaGip(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _BusquedaYPestanas(vm: vm, busqueda: busqueda),
                            _Lista(vm: vm, campos: _campos, web: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      mensajes,
                      TarjetaGip(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 380),
                            child: boton,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          children: [
                            encabezado,
                            const SizedBox(height: 14),
                            _AvanceMovil(vm: vm),
                            const SizedBox(height: 14),
                            busqueda,
                            const SizedBox(height: 14),
                            _FiltrosMovil(vm: vm),
                            const SizedBox(height: 14),
                            _Lista(vm: vm, campos: _campos, web: false),
                          ],
                        ),
                      ),
                      BarraInferiorMovimiento(
                        margen: 16,
                        hijos: [const SizedBox(height: 4), mensajes, boton],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Controlador y foco del campo "Contado" de cada producto, por id. Se crean
/// una sola vez y viven lo que vive la pantalla: al redibujar la lista (cada
/// tecla, un filtro, una fila que cambia de estado) el campo sigue siendo el
/// mismo y no pierde el foco ni el cursor.
class _CamposConteo {
  final _controladores = <String, TextEditingController>{};
  final _focos = <String, FocusNode>{};

  TextEditingController controlador(FilaConteo fila) =>
      _controladores.putIfAbsent(
        fila.producto.getId(),
        () => TextEditingController(text: fila.texto),
      );

  FocusNode foco(FilaConteo fila) => _focos.putIfAbsent(
    fila.producto.getId(),
    () => FocusNode(debugLabel: 'conteo_${fila.producto.getId()}'),
  );

  void sincronizar(FilaConteo fila) {
    final controlador = _controladores[fila.producto.getId()];
    if (controlador != null && controlador.text != fila.texto) {
      controlador.text = fila.texto;
    }
  }

  void dispose() {
    for (final c in _controladores.values) {
      c.dispose();
    }
    for (final f in _focos.values) {
      f.dispose();
    }
  }
}

/// Diferencia con signo como la ve el tendero: "+2", "−12", "0".
String mostrarDiferencia(Decimal diferencia) {
  if (diferencia == Decimal.zero) return '0';
  final signo = diferencia > Decimal.zero ? '+' : '−';
  return '$signo${mostrarCantidad(diferencia.abs())}';
}

/// La fila va en rojo: diferencia grande o error.
bool _enRojo(FilaConteo fila) =>
    fila.estado == EstadoFilaConteo.diferenciaGrande ||
    fila.estado == EstadoFilaConteo.error;

String _diferenciasGrandes(int n) =>
    n == 1 ? '1 diferencia grande' : '$n diferencias grandes';

/// "N de M contados" con el número grande en Archivo 800.
class _Avance extends StatelessWidget {
  const _Avance({required this.vm, required this.web});

  final ConteoViewModel vm;
  final bool web;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final numero = web
        ? tema.textTheme.headlineLarge
        : tema.textTheme.headlineSmall;
    final resto = web ? tema.textTheme.bodyLarge : tema.textTheme.bodyMedium;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${vm.contados}', style: numero?.cifrasTabulares),
          TextSpan(text: ' de ${vm.total} contados'),
        ],
      ),
      key: const Key('conteo_avance'),
      style: resto?.copyWith(color: tema.colorScheme.onSurfaceVariant),
    );
  }
}

/// Barra de avance del conteo.
class _BarraAvance extends StatelessWidget {
  const _BarraAvance({required this.vm, required this.alto});

  final ConteoViewModel vm;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(FormaGip.radioChip),
      child: LinearProgressIndicator(
        value: vm.total == 0 ? 0 : vm.contados / vm.total,
        minHeight: alto,
        color: tema.colorScheme.primary,
        backgroundColor: extra.separador,
      ),
    );
  }
}

/// Web: tarjeta "Avance del conteo" y, si hay diferencias grandes, la
/// tarjeta roja a la derecha (debajo si no cabe).
class _AvanceWeb extends StatelessWidget {
  const _AvanceWeb({required this.vm});

  final ConteoViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final avance = TarjetaGip(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text('Avance del conteo', style: tema.textTheme.titleLarge),
              _Avance(vm: vm, web: true),
            ],
          ),
          const SizedBox(height: 14),
          _BarraAvance(vm: vm, alto: 10),
          const SizedBox(height: 14),
          Text(
            'Los productos sin contar no cambian.',
            style: tema.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    if (vm.porRevisar == 0) return avance;
    final aviso = TarjetaAviso(
      key: const Key('conteo_aviso_revisar'),
      titulo: _diferenciasGrandes(vm.porRevisar),
      texto: ConteoViewModel.mensajeRevisar,
    );
    return LayoutBuilder(
      builder: (context, restricciones) {
        if (restricciones.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [avance, const SizedBox(height: 18), aviso],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: avance),
              const SizedBox(width: 18),
              Expanded(flex: 2, child: aviso),
            ],
          ),
        );
      },
    );
  }
}

/// Móvil: avance con la píldora "N por revisar" y la barra.
class _AvanceMovil extends StatelessWidget {
  const _AvanceMovil({required this.vm});

  final ConteoViewModel vm;

  @override
  Widget build(BuildContext context) => TarjetaGip(
    radio: FormaGip.radioTarjetaMovil,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _Avance(vm: vm, web: false)),
            if (vm.porRevisar > 0)
              PildoraEstado(
                key: const Key('conteo_aviso_revisar'),
                '${vm.porRevisar} por revisar',
                tono: TonoEstado.error,
              ),
          ],
        ),
        const SizedBox(height: 10),
        _BarraAvance(vm: vm, alto: 8),
      ],
    ),
  );
}

/// Web: búsqueda y filtros en pestañas, encima de la tabla.
class _BusquedaYPestanas extends StatelessWidget {
  const _BusquedaYPestanas({required this.vm, required this.busqueda});

  final ConteoViewModel vm;
  final Widget busqueda;

  @override
  Widget build(BuildContext context) {
    final extra = Theme.of(context).extension<ColoresExtraGip>()!;
    final pestanas = SelectorFiltro<FiltroConteo>(
      prefijoClave: 'conteo_filtro',
      estilo: EstiloFiltro.pestanas,
      elegido: vm.filtro,
      onElegir: vm.elegirFiltro,
      opciones: [
        (valor: FiltroConteo.todos, etiqueta: 'Todos · ${vm.total}'),
        (valor: FiltroConteo.contados, etiqueta: 'Contados · ${vm.contados}'),
        (
          valor: FiltroConteo.sinContar,
          etiqueta: 'Sin contar · ${vm.sinContar}',
        ),
        (
          valor: FiltroConteo.conDiferencia,
          etiqueta: 'Con diferencia · ${vm.conDiferencia}',
        ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: extra.separador)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: LayoutBuilder(
          builder: (context, restricciones) {
            if (restricciones.maxWidth >= 980) {
              return Row(
                children: [
                  Expanded(child: busqueda),
                  const SizedBox(width: 12),
                  pestanas,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                busqueda,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: pestanas),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Móvil: Todos, Sin contar · N y Diferencia · N en píldoras.
class _FiltrosMovil extends StatelessWidget {
  const _FiltrosMovil({required this.vm});

  final ConteoViewModel vm;

  @override
  Widget build(BuildContext context) => SelectorFiltro<FiltroConteo>(
    prefijoClave: 'conteo_filtro',
    elegido: vm.filtro,
    onElegir: vm.elegirFiltro,
    opciones: [
      (valor: FiltroConteo.todos, etiqueta: 'Todos'),
      (valor: FiltroConteo.sinContar, etiqueta: 'Sin contar · ${vm.sinContar}'),
      (
        valor: FiltroConteo.conDiferencia,
        etiqueta: 'Diferencia · ${vm.conDiferencia}',
      ),
    ],
  );
}

/// Lista de productos: tabla en la web, tarjeta con filas en el móvil.
class _Lista extends StatelessWidget {
  const _Lista({required this.vm, required this.campos, required this.web});

  final ConteoViewModel vm;
  final _CamposConteo campos;
  final bool web;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    if (vm.cargando) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final filas = vm.filas;
    if (filas.isEmpty) {
      final vacio = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          vm.total == 0
              ? 'Todavía no hay productos en el surtido'
              : 'Ningún producto coincide con la búsqueda',
          key: const Key('conteo_vacio'),
          textAlign: TextAlign.center,
          style: tema.textTheme.bodyMedium,
        ),
      );
      return web ? vacio : TarjetaGip(child: vacio);
    }
    final hijos = [
      for (final (i, fila) in filas.indexed) ...[
        if (i > 0) Divider(height: 1, color: extra.separador),
        web
            ? _FilaWeb(
                key: ValueKey('fila_${fila.producto.getId()}'),
                fila: fila,
                vm: vm,
                campos: campos,
              )
            : _FilaMovil(
                key: ValueKey('fila_${fila.producto.getId()}'),
                fila: fila,
                vm: vm,
                campos: campos,
              ),
      ],
    ];
    if (!web) {
      return TarjetaGip(
        radio: FormaGip.radioTarjetaMovil,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: hijos,
        ),
      );
    }
    final tabla = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [const _EncabezadoTabla(), ...hijos],
    );
    // Como el prototipo: por debajo de 780 px la tabla se desplaza de lado.
    return LayoutBuilder(
      builder: (context, restricciones) {
        if (restricciones.maxWidth >= _Columnas.anchoMinimo) return tabla;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: _Columnas.anchoMinimo, child: tabla),
        );
      },
    );
  }
}

/// Columnas de la tabla web: 2,2 · 1 · 1,2 · 1 · 1,6 con 16 px entre ellas.
abstract final class _Columnas {
  static const producto = 22;
  static const sistema = 10;
  static const contado = 12;
  static const diferencia = 10;
  static const estado = 16;
  static const espacio = 16.0;
  static const anchoCampo = 120.0;
  static const anchoMinimo = 780.0;
  static const relleno = EdgeInsets.symmetric(horizontal: 22, vertical: 12);
}

class _EncabezadoTabla extends StatelessWidget {
  const _EncabezadoTabla();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final estilo = tema.textTheme.labelMedium?.copyWith(
      fontSize: 13,
      letterSpacing: 0.5,
      color: tema.colorScheme.onSurfaceVariant,
    );
    Text t(String texto, [TextAlign alineacion = TextAlign.start]) =>
        Text(texto.toUpperCase(), style: estilo, textAlign: alineacion);
    return ColoredBox(
      color: extra.superficieSuave,
      child: Padding(
        padding: _Columnas.relleno,
        child: Row(
          children: [
            Expanded(flex: _Columnas.producto, child: t('Producto')),
            const SizedBox(width: _Columnas.espacio),
            Expanded(
              flex: _Columnas.sistema,
              child: t('Según el sistema', TextAlign.end),
            ),
            const SizedBox(width: _Columnas.espacio),
            Expanded(
              flex: _Columnas.contado,
              child: t('Contado', TextAlign.end),
            ),
            const SizedBox(width: _Columnas.espacio),
            Expanded(
              flex: _Columnas.diferencia,
              child: t('Diferencia', TextAlign.end),
            ),
            const SizedBox(width: _Columnas.espacio),
            Expanded(flex: _Columnas.estado, child: t('Estado')),
          ],
        ),
      ),
    );
  }
}

class _FilaWeb extends StatelessWidget {
  const _FilaWeb({
    super.key,
    required this.fila,
    required this.vm,
    required this.campos,
  });

  final FilaConteo fila;
  final ConteoViewModel vm;
  final _CamposConteo campos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final producto = fila.producto;
    return Container(
      key: Key('conteo_fila_${producto.getId()}'),
      // Siempre con color: si pasara de null a un color, el Container
      // insertaría un ColoredBox y el campo perdería el foco.
      color: _fondoFila(context, fila),
      padding: _Columnas.relleno,
      child: Row(
        children: [
          Expanded(
            flex: _Columnas.producto,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tema.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(
                      FormaGip.radioCajaIconoTabla,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: IconoPaquete(
                    tamano: 20,
                    color: esquema.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.getNombre(),
                        style: tema.textTheme.titleSmall?.copyWith(
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        nombreUnidad(producto.getUnidadMedida()),
                        style: tema.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: _Columnas.espacio),
          Expanded(
            flex: _Columnas.sistema,
            child: Text(
              mostrarCantidad(fila.item.getStockActual()),
              textAlign: TextAlign.end,
              style: tema.textTheme.titleMedium?.cifrasTabulares.copyWith(
                fontWeight: FontWeight.w400,
                color: esquema.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: _Columnas.espacio),
          Expanded(
            flex: _Columnas.contado,
            child: Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _Columnas.anchoCampo,
                ),
                child: _CampoContado(
                  key: ValueKey('contado_${producto.getId()}'),
                  fila: fila,
                  vm: vm,
                  controlador: campos.controlador(fila),
                  foco: campos.foco(fila),
                ),
              ),
            ),
          ),
          const SizedBox(width: _Columnas.espacio),
          Expanded(
            flex: _Columnas.diferencia,
            child: _Diferencia(fila: fila),
          ),
          const SizedBox(width: _Columnas.espacio),
          Expanded(
            flex: _Columnas.estado,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _EstadoWeb(fila: fila),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaMovil extends StatelessWidget {
  const _FilaMovil({
    super.key,
    required this.fila,
    required this.vm,
    required this.campos,
  });

  final FilaConteo fila;
  final ConteoViewModel vm;
  final _CamposConteo campos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final producto = fila.producto;
    final mensaje = switch (fila.estado) {
      EstadoFilaConteo.error => fila.error,
      EstadoFilaConteo.diferenciaGrande => ConteoViewModel.mensajeRevisar,
      _ => null,
    };
    final sistema = mostrarCantidad(fila.item.getStockActual());
    final unidad = fila.admiteDecimales
        ? ' ${unidadCorta(producto.getUnidadMedida())}'
        : '';
    return Container(
      key: Key('conteo_fila_${producto.getId()}'),
      // Siempre con color (ver _FilaWeb).
      color: _fondoFila(context, fila),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.getNombre(),
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Según el sistema: $sistema$unidad',
                      style: tema.textTheme.bodySmall?.cifrasTabulares.copyWith(
                        fontSize: 13,
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 92,
                child: _CampoContado(
                  key: ValueKey('contado_${producto.getId()}'),
                  fila: fila,
                  vm: vm,
                  controlador: campos.controlador(fila),
                  foco: campos.foco(fila),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 52, child: _Diferencia(fila: fila)),
            ],
          ),
          if (mensaje != null) ...[
            const SizedBox(height: 10),
            _MensajeFila(mensaje),
          ],
        ],
      ),
    );
  }
}

Color _fondoFila(BuildContext context, FilaConteo fila) {
  final tema = Theme.of(context);
  return _enRojo(fila)
      ? tema.extension<ColoresExtraGip>()!.errorFondoSuave
      : tema.colorScheme.surface;
}

/// Campo de la cantidad contada. El controlador y el foco son los de
/// [_CamposConteo]: no se crean aquí, para que sobrevivan al redibujo.
class _CampoContado extends StatelessWidget {
  const _CampoContado({
    super.key,
    required this.fila,
    required this.vm,
    required this.controlador,
    required this.foco,
  });

  final FilaConteo fila;
  final ConteoViewModel vm;
  final TextEditingController controlador;
  final FocusNode foco;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Semantics(
      label: 'Contado de ${fila.producto.getNombre()}',
      child: CampoGip(
        etiqueta: '',
        controlador: controlador,
        focusNode: foco,
        campoKey: Key('conteo_contado_${fila.producto.getId()}'),
        alto: 50,
        pista: '—',
        alineacion: TextAlign.end,
        resaltado: _enRojo(fila),
        estiloTexto: tema.textTheme.headlineSmall?.cifrasTabulares.copyWith(
          fontSize: 20,
        ),
        habilitado: !vm.registrando,
        tipoTeclado: TextInputType.numberWithOptions(
          decimal: fila.admiteDecimales,
        ),
        accionTeclado: TextInputAction.next,
        onChanged: (texto) => vm.cambiarCantidad(fila.producto, texto),
      ),
    );
  }
}

/// Diferencia en Archivo 800: verde si cuadra, roja si es grande o hay error,
/// "—" si no se conoce.
class _Diferencia extends StatelessWidget {
  const _Diferencia({required this.fila});

  final FilaConteo fila;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final diferencia = fila.diferencia;
    final estado = fila.estado;
    final color = switch (estado) {
      EstadoFilaConteo.cuadra => esquema.primary,
      EstadoFilaConteo.seAjusta => esquema.onSurface,
      EstadoFilaConteo.diferenciaGrande ||
      EstadoFilaConteo.error => esquema.error,
      EstadoFilaConteo.sinContar ||
      EstadoFilaConteo.calculando => esquema.onSurfaceVariant,
    };
    final conocida = diferencia != null && estado != EstadoFilaConteo.error;
    return Text(
      conocida ? mostrarDiferencia(diferencia) : '—',
      key: Key('conteo_diferencia_${fila.producto.getId()}'),
      textAlign: TextAlign.end,
      semanticsLabel: conocida ? null : 'Sin diferencia',
      style: tema.textTheme.titleLarge?.cifrasTabulares.copyWith(
        fontSize: 18,
        color: color,
      ),
    );
  }
}

/// Columna Estado de la web: píldora Cuadra, Se ajusta, Diferencia grande o
/// Sin contar; con error, el mensaje en rojo.
class _EstadoWeb extends StatelessWidget {
  const _EstadoWeb({required this.fila});

  final FilaConteo fila;

  @override
  Widget build(BuildContext context) {
    final clave = Key('conteo_estado_${fila.producto.getId()}');
    return switch (fila.estado) {
      EstadoFilaConteo.error => _MensajeFila(fila.error!, key: clave),
      EstadoFilaConteo.cuadra => PildoraEstado(
        'Cuadra',
        key: clave,
        tono: TonoEstado.bien,
      ),
      EstadoFilaConteo.seAjusta => PildoraEstado(
        'Se ajusta',
        key: clave,
        tono: TonoEstado.neutro,
      ),
      EstadoFilaConteo.diferenciaGrande => Semantics(
        key: clave,
        hint: ConteoViewModel.mensajeRevisar,
        child: const PildoraEstado('Diferencia grande', tono: TonoEstado.error),
      ),
      EstadoFilaConteo.sinContar => PildoraEstado(
        'Sin contar',
        key: clave,
        tono: TonoEstado.pendiente,
      ),
      EstadoFilaConteo.calculando => SizedBox.shrink(key: clave),
    };
  }
}

/// Mensaje de una fila en rojo (13 px, 600).
class _MensajeFila extends StatelessWidget {
  const _MensajeFila(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        texto,
        style: tema.textTheme.bodySmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: tema.colorScheme.error,
        ),
      ),
    );
  }
}
