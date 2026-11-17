import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/item_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/chip_estado.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/icono_paquete.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/selector_filtro.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/comun/tema/tipografia_gip.dart';
import 'package:gip/presentation/surtido/existencias_view_model.dart';
import 'package:gip/presentation/surtido/formato_movimiento.dart';
import 'package:gip/presentation/surtido/widgets_movimiento.dart';

/// Filtros de la lista: "Todos · N", "Agotados · N" y "Por peso" (DI-32).
class FiltrosExistencias extends StatelessWidget {
  const FiltrosExistencias({super.key, required this.vm});

  final ExistenciasViewModel vm;

  @override
  Widget build(BuildContext context) => SelectorFiltro<FiltroExistencias>(
    prefijoClave: 'existencias_filtro',
    elegido: vm.filtro,
    onElegir: vm.elegirFiltro,
    opciones: [
      (valor: FiltroExistencias.todos, etiqueta: 'Todos · ${vm.total}'),
      (
        valor: FiltroExistencias.agotados,
        etiqueta: 'Agotados · ${vm.agotados}',
      ),
      (valor: FiltroExistencias.porPeso, etiqueta: 'Por peso'),
    ],
  );
}

/// Existencias de Surtido (CUS-25, mockups `mExistencias` y `surtido-web.html`):
/// en el móvil, tarjeta con un producto por fila; en la web, tarjeta con el
/// título, los filtros y la tabla. Tocar un producto despliega sus últimos
/// movimientos.
class ListaExistencias extends StatelessWidget {
  const ListaExistencias({
    super.key,
    required this.vm,
    required this.web,
    required this.ahora,
  });

  final ExistenciasViewModel vm;
  final bool web;

  /// Momento de referencia para "Hoy" y "Ayer".
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final Widget cuerpo;
    if (!vm.cargado && vm.error == null) {
      cuerpo = const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (vm.error case final error? when !vm.cargado) {
      cuerpo = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TarjetaAviso(key: const Key('existencias_error'), titulo: error),
            const SizedBox(height: 12),
            BotonSecundario(
              texto: 'Intentar de nuevo',
              icono: Icons.refresh,
              onPressed: vm.cargar,
            ),
          ],
        ),
      );
    } else if (vm.visibles.isEmpty) {
      cuerpo = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          switch (vm.filtro) {
            _ when vm.total == 0 => 'Todavía no hay productos en el surtido',
            FiltroExistencias.agotados => 'No hay productos agotados',
            FiltroExistencias.porPeso =>
              'No hay productos que se vendan por '
                  'peso',
            FiltroExistencias.todos => '',
          },
          key: const Key('existencias_vacio'),
          textAlign: TextAlign.center,
          style: tema.textTheme.bodyMedium,
        ),
      );
    } else {
      final filas = [
        for (final (i, item) in vm.visibles.indexed) ...[
          if (i > 0) Divider(height: 1, color: extra.separador),
          web
              ? _FilaWeb(
                  key: ValueKey(
                    'existencias_fila_${item.getProducto().getId()}',
                  ),
                  item: item,
                  vm: vm,
                  ahora: ahora,
                )
              : _FilaMovil(
                  key: ValueKey(
                    'existencias_fila_${item.getProducto().getId()}',
                  ),
                  item: item,
                  vm: vm,
                  ahora: ahora,
                ),
        ],
      ];
      cuerpo = web
          ? _Tabla(filas: filas)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: filas,
            );
    }

    if (!web) {
      return TarjetaGip(radio: FormaGip.radioTarjetaMovil, child: cuerpo);
    }
    return TarjetaGip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Text(
                  'Existencias',
                  style: tema.textTheme.titleLarge?.copyWith(fontSize: 20),
                ),
                if (vm.cargado) FiltrosExistencias(vm: vm),
              ],
            ),
          ),
          Divider(height: 1, color: extra.separador),
          cuerpo,
        ],
      ),
    );
  }
}

/// Columnas de la tabla web (`surtido-web.html`): 2,4 · 1 · 1 · 1,3 · 1,6 con
/// 12 px entre ellas.
abstract final class _Columnas {
  static const producto = 24;
  static const unidad = 10;
  static const precio = 10;
  static const hay = 13;
  static const ultimo = 16;
  static const espacio = 12.0;
  static const anchoMinimo = 760.0;
  static const relleno = EdgeInsets.symmetric(horizontal: 22, vertical: 14);
}

class _Tabla extends StatelessWidget {
  const _Tabla({required this.filas});

  final List<Widget> filas;

  @override
  Widget build(BuildContext context) {
    final tabla = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [const _EncabezadoTabla(), ...filas],
    );
    // Como el prototipo: por debajo de 760 px la tabla se desplaza de lado.
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
    Widget t(
      int flex,
      String texto, [
      TextAlign alineacion = TextAlign.start,
    ]) => Expanded(
      flex: flex,
      child: Text(texto.toUpperCase(), style: estilo, textAlign: alineacion),
    );
    const espacio = SizedBox(width: _Columnas.espacio);
    return ColoredBox(
      color: extra.superficieSuave,
      child: Padding(
        padding: _Columnas.relleno.copyWith(top: 12, bottom: 12),
        child: Row(
          children: [
            t(_Columnas.producto, 'Producto'),
            espacio,
            t(_Columnas.unidad, 'Unidad'),
            espacio,
            t(_Columnas.precio, 'Precio', TextAlign.end),
            espacio,
            t(_Columnas.hay, 'Hay', TextAlign.end),
            espacio,
            t(_Columnas.ultimo, 'Último movimiento'),
          ],
        ),
      ),
    );
  }
}

/// Existencia en Archivo 800 con cifras tabulares (README del rediseño).
class _Hay extends StatelessWidget {
  const _Hay(this.item);

  final ItemInventario item;

  @override
  Widget build(BuildContext context) => Text(
    mostrarCantidad(item.getStockActual()),
    key: ValueKey('existencias_hay_${item.getProducto().getId()}'),
    style: Theme.of(context).textTheme.titleLarge?.cifrasTabulares
        .copyWith(fontSize: 20),
  );
}

/// Caja de 40 px con el ícono de paquete.
class _CajaIcono extends StatelessWidget {
  const _CajaIcono();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tema.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(FormaGip.radioCajaIconoTabla),
      ),
      alignment: Alignment.center,
      child: IconoPaquete(tamano: 20, color: tema.colorScheme.onSurfaceVariant),
    );
  }
}

class _FilaWeb extends StatefulWidget {
  const _FilaWeb({
    super.key,
    required this.item,
    required this.vm,
    required this.ahora,
  });

  final ItemInventario item;
  final ExistenciasViewModel vm;
  final DateTime ahora;

  @override
  State<_FilaWeb> createState() => _FilaWebState();
}

class _FilaWebState extends State<_FilaWeb> {
  @override
  void initState() {
    super.initState();
    // La columna se llena después de dibujar la tabla, fila por fila (DI-32).
    widget.vm.pedirUltimoMovimiento(widget.item.getProducto());
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final item = widget.item;
    final producto = item.getProducto();
    final vm = widget.vm;
    final abierto = vm.abierto == producto.getId();
    final secundario = tema.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      color: esquema.onSurfaceVariant,
    );
    final ultimo = vm.ultimoMovimiento(producto);
    const espacio = SizedBox(width: _Columnas.espacio);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: abierto,
          child: InkWell(
            onTap: () => vm.alternarDetalle(producto),
            child: Padding(
              padding: _Columnas.relleno,
              child: Row(
                children: [
                  Expanded(
                    flex: _Columnas.producto,
                    child: Row(
                      children: [
                        const _CajaIcono(),
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
                                producto.getCodigo(),
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
                  espacio,
                  Expanded(
                    flex: _Columnas.unidad,
                    child: Text(
                      nombreUnidad(producto.getUnidadMedida()),
                      style: secundario,
                    ),
                  ),
                  espacio,
                  Expanded(
                    flex: _Columnas.precio,
                    child: Text(
                      '\$ ${mostrarPrecio(producto.getPrecioVenta())}',
                      textAlign: TextAlign.end,
                      style: secundario?.cifrasTabulares,
                    ),
                  ),
                  espacio,
                  Expanded(
                    flex: _Columnas.hay,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (ExistenciasViewModel.estaAgotado(item))
                          const ChipEstado(EstadoExistencia.agotado),
                        _Hay(item),
                      ],
                    ),
                  ),
                  espacio,
                  Expanded(
                    flex: _Columnas.ultimo,
                    child: Text(
                      ultimo == null
                          ? ''
                          : resumenUltimoMovimiento(ultimo, widget.ahora),
                      key: ValueKey('existencias_ultimo_${producto.getId()}'),
                      style: secundario?.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (abierto)
          Padding(
            padding: const EdgeInsets.fromLTRB(74, 0, 22, 16),
            child: _PanelMovimientos(
              producto: producto,
              vm: vm,
              ahora: widget.ahora,
            ),
          ),
      ],
    );
  }
}

class _FilaMovil extends StatelessWidget {
  const _FilaMovil({
    super.key,
    required this.item,
    required this.vm,
    required this.ahora,
  });

  final ItemInventario item;
  final ExistenciasViewModel vm;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final producto = item.getProducto();
    final abierto = vm.abierto == producto.getId();
    return Semantics(
      button: true,
      expanded: abierto,
      child: InkWell(
        onTap: () => vm.alternarDetalle(producto),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${nombreUnidad(producto.getUnidadMedida())} · '
                          '\$ ${mostrarPrecio(producto.getPrecioVenta())}',
                          style: tema.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Hay(item),
                      if (ExistenciasViewModel.estaAgotado(item)) ...[
                        const SizedBox(height: 4),
                        const ChipEstado(EstadoExistencia.agotado),
                      ],
                    ],
                  ),
                ],
              ),
              if (abierto) ...[
                const SizedBox(height: 12),
                _PanelMovimientos(producto: producto, vm: vm, ahora: ahora),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel "Últimos movimientos" (mockup `mExistencias`): los
/// [ExistenciasViewModel.movimientosRecientes] más recientes de los últimos
/// [ExistenciasViewModel.diasRecientes] días. "Ver historial completo" llega
/// después (DI-32).
class _PanelMovimientos extends StatelessWidget {
  const _PanelMovimientos({
    required this.producto,
    required this.vm,
    required this.ahora,
  });

  final Producto producto;
  final ExistenciasViewModel vm;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final historial = vm.historial;
    final Widget contenido;
    if (historial == null || historial.cargando) {
      contenido = const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    } else if (historial.error case final error?) {
      contenido = Text(
        error,
        style: tema.textTheme.bodyMedium?.copyWith(color: esquema.error),
      );
    } else if (historial.movimientos.isEmpty) {
      contenido = Text(
        'Sin movimientos en los últimos '
        '${ExistenciasViewModel.diasRecientes} días',
        style: tema.textTheme.bodyMedium?.copyWith(
          color: esquema.onSurfaceVariant,
        ),
      );
    } else {
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final m in historial.movimientos.take(
            ExistenciasViewModel.movimientosRecientes,
          ))
            _LineaMovimiento(movimiento: m, ahora: ahora),
        ],
      );
    }
    return Container(
      key: ValueKey('existencias_detalle_${producto.getId()}'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: tema.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(FormaGip.radioCampo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 20, color: esquema.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Últimos movimientos',
                  style: tema.textTheme.titleSmall?.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          contenido,
        ],
      ),
    );
  }
}

class _LineaMovimiento extends StatelessWidget {
  const _LineaMovimiento({required this.movimiento, required this.ahora});

  final MovimientoInventario movimiento;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final estado = estadoMovimiento(movimiento);
    final suma = movimiento.getCantidad() > Decimal.zero;
    return Padding(
      key: ValueKey('existencias_movimiento_${movimiento.getId()}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${cuandoMovimiento(movimiento.getFecha(), ahora)} · '
              '${descripcionMovimiento(movimiento)}',
              style: tema.textTheme.bodyMedium?.copyWith(fontSize: 15),
            ),
          ),
          if (estado != null) ...[
            const SizedBox(width: 8),
            PildoraEstado(estado.texto, tono: estado.tono),
          ],
          const SizedBox(width: 12),
          Text(
            cantidadConSigno(movimiento.getCantidad()),
            style: tema.textTheme.titleSmall?.cifrasTabulares.copyWith(
              fontSize: 15,
              color: suma ? esquema.primary : esquema.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
