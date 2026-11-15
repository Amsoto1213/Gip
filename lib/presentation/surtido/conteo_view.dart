import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/barra_busqueda.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/selector_filtro.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/surtido/conteo_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:gip/presentation/surtido/widgets_movimiento.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Conteo físico (CUS-04), según los mockups `mConteo` y `Conteo`:
/// avance, búsqueda por nombre, filtros y la lista de productos con lo que
/// dice el sistema, el campo de lo contado y la diferencia. Una diferencia que
/// supera el umbral se marca en amarillo con el aviso del diagrama y "Volver a
/// contar"; no bloquea.
///
/// No se muestran el lector, "se guarda mientras avanza", "Pausar y seguir
/// después", quién empezó el conteo, "Imprimir etiquetas QR" ni "Cambiar el
/// límite": el caso de uso no los entrega (DI-24).
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
          ? 'Escriba lo que contó de cada producto. Al confirmar, la '
                'existencia queda igual a lo contado.'
          : null,
      onVolver: _volver,
    );
    final boton = BotonPrimario(
      key: const Key('conteo_confirmar'),
      texto: vm.contados == 1
          ? 'Confirmar ajuste de 1 producto'
          : 'Confirmar ajuste de ${vm.contados} productos',
      icono: Icons.check,
      cargando: vm.registrando,
      onPressed: vm.puedeConfirmar ? _confirmar : null,
    );
    final nota = vm.sinContar == 1
        ? 'Al confirmar, la existencia de cada producto contado queda igual a '
              'lo que usted contó. El que falta por contar no cambia.'
        : 'Al confirmar, la existencia de cada producto contado queda igual a '
              'lo que usted contó. Los ${vm.sinContar} sin contar no cambian.';

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
                      const SizedBox(height: 24),
                      _AvanceYAviso(vm: vm, web: true),
                      const SizedBox(height: 24),
                      TarjetaGip(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _BusquedaYFiltros(
                              vm: vm,
                              controlador: _busqueda,
                              web: true,
                            ),
                            const SizedBox(height: 16),
                            _Lista(vm: vm, campos: _campos, web: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      MensajesMovimiento(error: vm.error, aviso: vm.aviso),
                      _BarraConfirmarWeb(nota: nota, boton: boton),
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
                            const SizedBox(height: 16),
                            _AvanceYAviso(vm: vm, web: false),
                            const SizedBox(height: 16),
                            _BusquedaYFiltros(
                              vm: vm,
                              controlador: _busqueda,
                              web: false,
                            ),
                            const SizedBox(height: 16),
                            _Lista(vm: vm, campos: _campos, web: false),
                          ],
                        ),
                      ),
                      BarraInferiorMovimiento(
                        margen: 16,
                        hijos: [
                          MensajesMovimiento(error: vm.error, aviso: vm.aviso),
                          Text(
                            nota,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          boton,
                        ],
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

/// "42 de 128 contados" con su barra y, si hay diferencias grandes, el aviso
/// (en la web, a la derecha).
class _AvanceYAviso extends StatelessWidget {
  const _AvanceYAviso({required this.vm, required this.web});

  final ConteoViewModel vm;
  final bool web;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final fraccion = vm.total == 0 ? 0.0 : vm.contados / vm.total;
    final avance = Column(
      key: const Key('conteo_avance'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${vm.contados} de ${vm.total} contados',
          style: tema.textTheme.titleMedium?.cifrasTabulares,
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(FormaGip.radioChip),
          child: LinearProgressIndicator(
            value: fraccion,
            minHeight: 10,
            color: tema.colorScheme.primary,
            backgroundColor: tema.colorScheme.outlineVariant,
          ),
        ),
      ],
    );
    final aviso = vm.porRevisar == 0 ? null : _AvisoRevisar(vm.porRevisar);
    if (!web) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          avance,
          if (aviso != null) ...[const SizedBox(height: 12), aviso],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: TarjetaGip(
              padding: const EdgeInsets.all(24),
              child: Center(child: avance),
            ),
          ),
          if (aviso != null) ...[
            const SizedBox(width: 24),
            Expanded(flex: 2, child: aviso),
          ],
        ],
      ),
    );
  }
}

/// Recuadro amarillo con cuántos productos superan el umbral.
class _AvisoRevisar extends StatelessWidget {
  const _AvisoRevisar(this.cantidad);

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('conteo_aviso_revisar'),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: extra.alertaFondo,
          borderRadius: BorderRadius.circular(FormaGip.radioTarjeta),
          border: Border.all(color: extra.alertaBorde),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: extra.alertaTexto),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cantidad == 1
                        ? '1 diferencia grande'
                        : '$cantidad diferencias grandes',
                    style: tema.textTheme.titleSmall?.copyWith(
                      color: extra.alertaTexto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ConteoViewModel.mensajeRevisar,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: extra.alertaTexto,
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
}

/// Búsqueda por nombre y filtros. En la web, lado a lado si caben.
class _BusquedaYFiltros extends StatelessWidget {
  const _BusquedaYFiltros({
    required this.vm,
    required this.controlador,
    required this.web,
  });

  final ConteoViewModel vm;
  final TextEditingController controlador;
  final bool web;

  @override
  Widget build(BuildContext context) {
    final busqueda = BarraBusqueda(
      pista: 'Buscar producto por nombre…',
      controlador: controlador,
      campoKey: const Key('conteo_buscar'),
      onChanged: vm.buscar,
    );
    final filtros = SelectorFiltro<FiltroConteo>(
      prefijoClave: 'conteo_filtro',
      elegido: vm.filtro,
      onElegir: vm.elegirFiltro,
      opciones: [
        (valor: FiltroConteo.todos, etiqueta: 'Todos'),
        (valor: FiltroConteo.contados, etiqueta: 'Contados'),
        (valor: FiltroConteo.sinContar, etiqueta: 'Sin contar'),
        (
          valor: FiltroConteo.conDiferencia,
          etiqueta: 'Con diferencia · ${vm.conDiferencia}',
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, restricciones) {
        if (web && restricciones.maxWidth >= 960) {
          return Row(
            children: [
              Expanded(child: busqueda),
              const SizedBox(width: 16),
              filtros,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [busqueda, const SizedBox(height: 12), filtros],
        );
      },
    );
  }
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
    if (vm.cargando) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final filas = vm.filas;
    if (filas.isEmpty) {
      return Padding(
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
    }
    final hijos = [
      for (final (i, fila) in filas.indexed) ...[
        if (i > 0) Divider(height: 1, color: tema.colorScheme.outlineVariant),
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
    if (web) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [const _EncabezadoTabla(), ...hijos],
      );
    }
    return TarjetaGip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: hijos,
      ),
    );
  }
}

/// Anchos de las columnas de la tabla web.
abstract final class _Columnas {
  static const contado = 120.0;
  static const estado = 170.0;
  static const espacio = 16.0;
}

class _EncabezadoTabla extends StatelessWidget {
  const _EncabezadoTabla();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estilo = tema.textTheme.labelMedium?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
    );
    Text t(String texto, [TextAlign alineacion = TextAlign.start]) =>
        Text(texto, style: estilo, textAlign: alineacion);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: t('Producto')),
          Expanded(flex: 2, child: t('Código')),
          Expanded(flex: 2, child: t('Según el sistema', TextAlign.end)),
          const SizedBox(width: _Columnas.espacio),
          SizedBox(
            width: _Columnas.contado,
            child: t('Contado', TextAlign.end),
          ),
          const SizedBox(width: _Columnas.espacio),
          Expanded(child: t('Diferencia', TextAlign.end)),
          const SizedBox(width: _Columnas.espacio),
          SizedBox(width: _Columnas.estado, child: t('Estado')),
        ],
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
    final extra = tema.extension<ColoresExtraGip>()!;
    final producto = fila.producto;
    final cifras = tema.textTheme.bodyLarge?.cifrasTabulares;
    return Container(
      key: Key('conteo_fila_${producto.getId()}'),
      color: fila.revisar ? extra.alertaFondo : tema.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  producto.getNombre(),
                  style: tema.textTheme.titleSmall,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  producto.getCodigo(),
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  mostrarCantidad(fila.item.getStockActual()),
                  textAlign: TextAlign.end,
                  style: cifras,
                ),
              ),
              const SizedBox(width: _Columnas.espacio),
              SizedBox(
                width: _Columnas.contado,
                child: _CampoContado(
                  key: ValueKey('contado_${producto.getId()}'),
                  fila: fila,
                  vm: vm,
                  controlador: campos.controlador(fila),
                  foco: campos.foco(fila),
                ),
              ),
              const SizedBox(width: _Columnas.espacio),
              Expanded(child: _Diferencia(fila: fila)),
              const SizedBox(width: _Columnas.espacio),
              SizedBox(
                width: _Columnas.estado,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Estado(fila: fila, vm: vm),
                ),
              ),
            ],
          ),
          if (fila.error != null) ...[
            const SizedBox(height: 6),
            _ErrorFila(fila.error!),
          ],
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
    final extra = tema.extension<ColoresExtraGip>()!;
    final producto = fila.producto;
    return Container(
      key: Key('conteo_fila_${producto.getId()}'),
      color: fila.revisar ? extra.alertaFondo : tema.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                      style: tema.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Según el sistema: '
                      '${mostrarCantidad(fila.item.getStockActual())}',
                      style: tema.textTheme.bodySmall?.cifrasTabulares,
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
              SizedBox(width: 56, child: _Diferencia(fila: fila)),
            ],
          ),
          if (fila.revisar) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    ConteoViewModel.mensajeRevisar,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: extra.alertaTexto,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _BotonVolverAContar(fila: fila, vm: vm),
              ],
            ),
          ],
          if (fila.error != null) ...[
            const SizedBox(height: 8),
            _ErrorFila(fila.error!),
          ],
        ],
      ),
    );
  }
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
    return Semantics(
      label: 'Cantidad contada de ${fila.producto.getNombre()}',
      child: CampoGip(
        etiqueta: '',
        controlador: controlador,
        focusNode: foco,
        campoKey: Key('conteo_contado_${fila.producto.getId()}'),
        alto: 48,
        alineacion: TextAlign.end,
        resaltado: fila.revisar,
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

class _Diferencia extends StatelessWidget {
  const _Diferencia({required this.fila});

  final FilaConteo fila;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final diferencia = fila.diferencia;
    final color = diferencia == null
        ? tema.colorScheme.onSurfaceVariant
        : fila.revisar
        ? extra.alertaTexto
        : diferencia == Decimal.zero
        ? tema.colorScheme.primary
        : tema.colorScheme.onSurface;
    return Text(
      diferencia == null ? '' : mostrarDiferencia(diferencia),
      key: Key('conteo_diferencia_${fila.producto.getId()}'),
      textAlign: TextAlign.end,
      style: tema.textTheme.titleMedium?.cifrasTabulares.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Columna Estado de la web: "Cuadra", "Se ajusta" o "Volver a contar".
class _Estado extends StatelessWidget {
  const _Estado({required this.fila, required this.vm});

  final FilaConteo fila;
  final ConteoViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final diferencia = fila.diferencia;
    if (diferencia == null) return const SizedBox.shrink();
    if (fila.revisar) return _BotonVolverAContar(fila: fila, vm: vm);
    final cuadra = diferencia == Decimal.zero;
    return Text(
      cuadra ? 'Cuadra' : 'Se ajusta',
      style: tema.textTheme.labelLarge?.copyWith(
        color: cuadra ? tema.colorScheme.primary : tema.colorScheme.onSurface,
      ),
    );
  }
}

class _BotonVolverAContar extends StatelessWidget {
  const _BotonVolverAContar({required this.fila, required this.vm});

  final FilaConteo fila;
  final ConteoViewModel vm;

  @override
  Widget build(BuildContext context) => BotonSecundario(
    key: Key('conteo_volver_${fila.producto.getId()}'),
    texto: 'Volver a contar',
    alto: 44,
    onPressed: vm.registrando ? null : () => vm.volverAContar(fila.producto),
  );
}

class _ErrorFila extends StatelessWidget {
  const _ErrorFila(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Text(
      texto,
      style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.error),
    );
  }
}

/// Franja oscura de la web con la nota y el botón de confirmar.
class _BarraConfirmarWeb extends StatelessWidget {
  const _BarraConfirmarWeb({required this.nota, required this.boton});

  final String nota;
  final Widget boton;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final texto = Text(
      nota,
      style: tema.textTheme.bodyMedium?.copyWith(
        color: tema.colorScheme.onPrimary,
      ),
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: extra.navFondo,
        borderRadius: BorderRadius.circular(FormaGip.radioTarjeta),
      ),
      child: LayoutBuilder(
        builder: (context, restricciones) {
          if (restricciones.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [texto, const SizedBox(height: 16), boton],
            );
          }
          return Row(
            children: [
              Expanded(child: texto),
              const SizedBox(width: 24),
              SizedBox(width: 340, child: boton),
            ],
          );
        },
      ),
    );
  }
}
