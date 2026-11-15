import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/opcion_con_icono.dart';
import 'package:gip/presentation/comun/resumen_movimiento.dart';
import 'package:gip/presentation/comun/seccion_numerada.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/surtido/perdida_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:gip/presentation/surtido/widgets_movimiento.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Pérdida o devolución (CUS-03), según
/// `docs/ui/rediseno/perdida-web.html`: sección 1 "Producto y cantidad",
/// sección 2 "Motivo" y, en la web, el resumen a la derecha.
///
/// El producto se elige en Buscar producto (CUS-06) en modo seleccionar; si la
/// pantalla abre sin producto, la búsqueda se abre sola. El motivo se elige de
/// la lista cerrada y sin él no se puede confirmar (IE-03).
class PerdidaView extends StatefulWidget {
  const PerdidaView({super.key});

  @override
  State<PerdidaView> createState() => _PerdidaViewState();
}

class _PerdidaViewState extends State<PerdidaView> {
  final _cantidad = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (context.read<PerdidaViewModel>().producto == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _elegirProducto();
      });
    }
  }

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  Future<void> _elegirProducto() async {
    final vm = context.read<PerdidaViewModel>();
    final producto = await elegirProducto(context);
    if (producto != null) await vm.elegirProducto(producto);
  }

  void _sumar(int paso) {
    final cantidad = context.read<PerdidaViewModel>().sumarCantidad(
      Decimal.fromInt(paso),
    );
    _cantidad.text = mostrarCantidad(cantidad);
  }

  /// Atajo "Todas (N)": pone toda la existencia como cantidad. Solo cambia el
  /// campo; las reglas siguen en el view model (DI-23).
  void _todas(Decimal existencia) {
    _cantidad.text = mostrarCantidad(existencia);
    context.read<PerdidaViewModel>().cambiarCantidad(_cantidad.text);
  }

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    final registrada = await context.read<PerdidaViewModel>().registrar();
    if (registrada) _cantidad.clear();
  }

  void _volver() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(rutaPrincipalSurtido);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PerdidaViewModel>();
    final web = FormaGip.esWeb(context);
    final boton = BotonPrimario(
      key: const Key('perdida_registrar'),
      texto: 'Registrar pérdida',
      icono: Icons.check,
      cargando: vm.registrando,
      onPressed: vm.puedeConfirmar ? _registrar : null,
    );
    final encabezado = EncabezadoPantalla(
      titulo: web ? 'Registrar pérdida o devolución' : 'Pérdida o devolución',
      miga: 'Pérdida o devolución',
      seccion: 'Surtido',
      contexto: web
          ? 'Saque del surtido lo que se venció, se dañó o se le devolvió al '
                'proveedor.'
          : null,
      onVolver: _volver,
    );
    final secciones = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _seccionProducto(vm),
        const SizedBox(height: 18),
        _seccionMotivo(vm),
      ],
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
                      const SizedBox(height: 24),
                      ColumnasMovimiento(
                        formulario: secciones,
                        resumen: _Resumen(
                          vm: vm,
                          boton: boton,
                          onCancelar: _volver,
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
                            const SizedBox(height: 16),
                            secciones,
                            const SizedBox(height: 12),
                            const _NotaMotivo(),
                          ],
                        ),
                      ),
                      BarraInferiorMovimiento(
                        margen: 16,
                        hijos: [
                          MensajesMovimiento(error: vm.error, aviso: vm.aviso),
                          FilaResumen(
                            'Existencia quedará en',
                            _quedaraEnLargo(vm),
                          ),
                          const SizedBox(height: 8),
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

  Widget _seccionProducto(PerdidaViewModel vm) {
    final habilitado = !vm.registrando;
    final producto = vm.producto;
    final existencia = vm.existencia;
    return SeccionNumerada(
      numero: 1,
      titulo: 'Producto y cantidad',
      padding: EdgeInsets.zero,
      child: PanelesProductoCantidad(
        producto: PanelProducto(
          prefijoClave: 'perdida',
          producto: producto,
          textoSinProducto: '¿Qué producto sale?',
          existencia: existencia == null
              ? null
              : 'Hay ${mostrarCantidad(existencia)}',
          habilitado: habilitado,
          onElegir: _elegirProducto,
        ),
        cantidad: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EtiquetaPanel('¿Cuántas salen del surtido?'),
            const SizedBox(height: 12),
            SelectorCantidad(
              prefijoClave: 'perdida',
              controlador: _cantidad,
              habilitado: habilitado,
              decimales: vm.admiteDecimales,
              unidad: producto == null
                  ? null
                  : unidadCorta(producto.getUnidadMedida()),
              onCambio: vm.cambiarCantidad,
              onSumar: _sumar,
            ),
            if (existencia != null && existencia > Decimal.zero) ...[
              const SizedBox(height: 12),
              AtajoCantidad(
                key: const Key('perdida_todas'),
                texto: 'Todas (${mostrarCantidad(existencia)})',
                onPressed: habilitado ? () => _todas(existencia) : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _seccionMotivo(PerdidaViewModel vm) => SeccionNumerada(
    numero: 2,
    titulo: 'Motivo',
    etiqueta: 'Obligatorio',
    child: _SelectorMotivo(
      seleccionado: vm.motivo,
      habilitado: !vm.registrando,
      onElegir: (motivo) {
        // Cierra el teclado de la cantidad al elegir el motivo.
        FocusScope.of(context).unfocus();
        vm.elegirMotivo(motivo);
      },
    ),
  );
}

/// Nombre del motivo como lo ve el tendero.
String _nombreMotivo(MotivoMerma motivo) => switch (motivo) {
  MotivoMerma.vencido => 'Vencido',
  MotivoMerma.danado => 'Dañado',
  MotivoMerma.devueltoProveedor => 'Devuelto al proveedor',
  MotivoMerma.otro => 'Otro',
};

/// Descripción del motivo (`docs/ui/rediseno/README.md`).
String _descripcionMotivo(MotivoMerma motivo) => switch (motivo) {
  MotivoMerma.vencido => 'Pasó la fecha de vencimiento',
  MotivoMerma.danado => 'Roto, mojado o abierto',
  MotivoMerma.devueltoProveedor => 'Se lo lleva el proveedor',
  MotivoMerma.otro => 'Cualquier otra razón',
};

IconData _iconoMotivo(MotivoMerma motivo) => switch (motivo) {
  MotivoMerma.vencido => Icons.event_busy_outlined,
  MotivoMerma.danado => Icons.broken_image_outlined,
  MotivoMerma.devueltoProveedor => Icons.local_shipping_outlined,
  MotivoMerma.otro => Icons.more_horiz,
};

/// "12 unidades", "1 unidad", "2,5 kg".
String _cantidadLarga(Decimal cantidad, UnidadMedida unidad) {
  final texto = mostrarCantidad(cantidad);
  return switch (unidad) {
    UnidadMedida.unidad when cantidad == Decimal.one => '$texto unidad',
    UnidadMedida.unidad => '$texto unidades',
    _ => '$texto ${unidadCorta(unidad)}',
  };
}

String _quedaraEnLargo(PerdidaViewModel vm) {
  final quedara = vm.quedaraEn;
  final producto = vm.producto;
  if (quedara == null || producto == null) return '—';
  return _cantidadLarga(quedara, producto.getUnidadMedida());
}

/// Lista cerrada de motivos en 2 x 2 (IE-03 b); en una pantalla angosta, uno
/// por fila.
class _SelectorMotivo extends StatelessWidget {
  const _SelectorMotivo({
    required this.seleccionado,
    required this.habilitado,
    required this.onElegir,
  });

  final MotivoMerma? seleccionado;
  final bool habilitado;
  final ValueChanged<MotivoMerma> onElegir;

  static const _separacion = 12.0;

  /// Ancho mínimo de cada opción para que el título y la descripción no se
  /// corten feo.
  static const _anchoMinimo = 250.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, restricciones) {
      final escala = MediaQuery.textScalerOf(context).scale(1);
      final columnas =
          (restricciones.maxWidth - _separacion) / 2 >= _anchoMinimo * escala
          ? 2
          : 1;
      const motivos = MotivoMerma.values;
      final filas = <Widget>[];
      for (var i = 0; i < motivos.length; i += columnas) {
        if (i > 0) filas.add(const SizedBox(height: _separacion));
        filas.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (
                  var j = i;
                  j < i + columnas && j < motivos.length;
                  j++
                ) ...[
                  if (j > i) const SizedBox(width: _separacion),
                  Expanded(
                    child: OpcionConIcono(
                      key: Key('perdida_motivo_${motivos[j].name}'),
                      icono: _iconoMotivo(motivos[j]),
                      titulo: _nombreMotivo(motivos[j]),
                      descripcion: _descripcionMotivo(motivos[j]),
                      elegida: motivos[j] == seleccionado,
                      onTap: habilitado ? () => onElegir(motivos[j]) : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }
      return Semantics(
        label: 'Motivo (obligatorio)',
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: filas,
        ),
      );
    },
  );
}

/// Columna derecha en la web: [ResumenMovimiento] con la existencia, lo que
/// sale y el motivo.
class _Resumen extends StatelessWidget {
  const _Resumen({
    required this.vm,
    required this.boton,
    required this.onCancelar,
  });

  final PerdidaViewModel vm;
  final Widget boton;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final producto = vm.producto;
    final unidad = producto == null
        ? ''
        : ' ${unidadCorta(producto.getUnidadMedida())}';
    final existencia = vm.existencia;
    final cantidad = vm.cantidad;
    final quedara = vm.quedaraEn;
    final motivo = vm.motivo;
    final fraccion =
        existencia != null && quedara != null && existencia > Decimal.zero
        ? quedara.toDouble() / existencia.toDouble()
        : null;
    return ResumenMovimiento(
      antes: existencia == null ? '—' : mostrarCantidad(existencia),
      despues: quedara == null ? '—' : mostrarCantidad(quedara),
      fraccionQueda: fraccion,
      detalles: [
        FilaDetalle('Producto', producto?.getNombre() ?? '—'),
        FilaDetalle(
          'Salen',
          cantidad == null ? '—' : '− ${mostrarCantidad(cantidad)}$unidad',
          resta: cantidad != null,
        ),
        FilaDetalle('Motivo', motivo == null ? '—' : _nombreMotivo(motivo)),
      ],
      pie: [
        MensajesMovimiento(error: vm.error, aviso: vm.aviso),
        boton,
        const SizedBox(height: 4),
        BotonSecundario(
          texto: 'Cancelar',
          sinBorde: true,
          expandido: true,
          onPressed: vm.registrando ? null : onCancelar,
        ),
        const SizedBox(height: 6),
        const _NotaMotivo(),
      ],
    );
  }
}

/// Nota bajo el resumen (web) o bajo los motivos (móvil).
class _NotaMotivo extends StatelessWidget {
  const _NotaMotivo();

  @override
  Widget build(BuildContext context) => Text(
    'El motivo queda guardado y aparece en el reporte de pérdidas del mes.',
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontSize: 13, height: 1.45),
  );
}
