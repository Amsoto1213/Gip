import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/resumen_movimiento.dart';
import 'package:gip/presentation/comun/seccion_numerada.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/surtido/entrada_mercancia_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:gip/presentation/surtido/widgets_movimiento.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Entrada de mercancía (CUS-01), con el patrón de Pérdida
/// (`docs/ui/rediseno/README.md`): sección 1 "Producto y cantidad", sección 2
/// "Costo y factura" y, en la web, el resumen a la derecha.
///
/// El producto se elige en Buscar producto (CUS-06) en modo seleccionar; si la
/// pantalla abre sin producto, la búsqueda se abre sola. Sin "Hay N · último
/// costo" ni "Quedará en": el diseño no los entrega (DI-20); el resumen muestra
/// lo que llega y el total de la compra (DI-23).
class EntradaMercanciaView extends StatefulWidget {
  const EntradaMercanciaView({super.key});

  @override
  State<EntradaMercanciaView> createState() => _EntradaMercanciaViewState();
}

class _EntradaMercanciaViewState extends State<EntradaMercanciaView> {
  final _cantidad = TextEditingController();
  final _costo = TextEditingController();
  final _factura = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (context.read<EntradaMercanciaViewModel>().producto == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _elegirProducto();
      });
    }
  }

  @override
  void dispose() {
    _cantidad.dispose();
    _costo.dispose();
    _factura.dispose();
    super.dispose();
  }

  Future<void> _elegirProducto() async {
    final vm = context.read<EntradaMercanciaViewModel>();
    final producto = await elegirProducto(context);
    if (producto != null) await vm.elegirProducto(producto);
  }

  void _sumar(int paso) {
    final cantidad = context.read<EntradaMercanciaViewModel>().sumarCantidad(
      Decimal.fromInt(paso),
    );
    _cantidad.text = mostrarCantidad(cantidad);
  }

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    final registrada = await context
        .read<EntradaMercanciaViewModel>()
        .registrar(_factura.text);
    if (registrada) {
      _cantidad.clear();
      _costo.clear();
      _factura.clear();
    }
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
    final vm = context.watch<EntradaMercanciaViewModel>();
    final web = FormaGip.esWeb(context);
    final boton = BotonPrimario(
      key: const Key('entrada_registrar'),
      texto: 'Registrar entrada',
      icono: Icons.check,
      cargando: vm.registrando,
      onPressed: _registrar,
    );
    final encabezado = EncabezadoPantalla(
      titulo: web ? 'Registrar entrada de mercancía' : 'Entrada de mercancía',
      miga: 'Entrada de mercancía',
      seccion: 'Surtido',
      contexto: web
          ? 'Sume al surtido la mercancía que llegó del proveedor.'
          : null,
      onVolver: _volver,
    );
    final secciones = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _seccionProducto(vm),
        const SizedBox(height: 18),
        _seccionCosto(vm),
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
                          ],
                        ),
                      ),
                      BarraInferiorMovimiento(
                        margen: 16,
                        hijos: [
                          MensajesMovimiento(error: vm.error, aviso: vm.aviso),
                          FilaResumen(
                            'Total de la compra',
                            _total(vm),
                            destacada: true,
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

  Widget _seccionProducto(EntradaMercanciaViewModel vm) {
    final habilitado = !vm.registrando;
    final producto = vm.producto;
    return SeccionNumerada(
      numero: 1,
      titulo: 'Producto y cantidad',
      padding: EdgeInsets.zero,
      child: PanelesProductoCantidad(
        producto: PanelProducto(
          prefijoClave: 'entrada',
          producto: producto,
          textoSinProducto: '¿Qué producto llegó?',
          habilitado: habilitado,
          onElegir: _elegirProducto,
        ),
        cantidad: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EtiquetaPanel('¿Cuántas unidades llegaron?'),
            const SizedBox(height: 12),
            SelectorCantidad(
              prefijoClave: 'entrada',
              controlador: _cantidad,
              habilitado: habilitado,
              unidad: producto == null
                  ? null
                  : unidadCorta(producto.getUnidadMedida()),
              onCambio: vm.cambiarCantidad,
              onSumar: _sumar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionCosto(EntradaMercanciaViewModel vm) {
    final habilitado = !vm.registrando;
    final costo = CampoGip(
      etiqueta: 'Costo por unidad',
      controlador: _costo,
      campoKey: const Key('entrada_costo'),
      icono: Icons.payments_outlined,
      prefijo: r'$ ',
      pista: '0',
      habilitado: habilitado,
      tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
      accionTeclado: TextInputAction.next,
      onChanged: vm.cambiarCosto,
    );
    final factura = CampoGip(
      etiqueta: 'N.º de factura (opcional)',
      controlador: _factura,
      campoKey: const Key('entrada_factura'),
      icono: Icons.receipt_long_outlined,
      pista: 'Ej.: FV-10231',
      habilitado: habilitado,
      accionTeclado: TextInputAction.done,
    );
    return SeccionNumerada(
      numero: 2,
      titulo: 'Costo y factura',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, restricciones) => restricciones.maxWidth >= 520
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: costo),
                      const SizedBox(width: 16),
                      Expanded(child: factura),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [costo, const SizedBox(height: 16), factura],
                  ),
          ),
          if (vm.costoDifiere) ...[
            const SizedBox(height: 16),
            const _AdvertenciaCosto(),
          ],
        ],
      ),
    );
  }
}

/// Advertencia del diagrama (paso 11). No bloquea el registro.
class _AdvertenciaCosto extends StatelessWidget {
  const _AdvertenciaCosto();

  @override
  Widget build(BuildContext context) {
    final extra = Theme.of(context).extension<ColoresExtraGip>()!;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('entrada_advertencia_costo'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: extra.alertaFondo,
          border: Border.all(color: extra.alertaBorde),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: extra.alertaTexto),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(color: extra.alertaTexto),
                  children: const [
                    TextSpan(
                      text: EntradaMercanciaViewModel.mensajeCostoDistinto,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          '. Revíselo; si está bien, puede guardar '
                          'igual.',
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

String _total(EntradaMercanciaViewModel vm) {
  final total = vm.totalCompra;
  return total == null ? r'$ —' : '\$ ${mostrarPrecio(total)}';
}

/// Columna derecha en la web: lo que llega y el total de la compra (sin barra:
/// en una entrada el surtido sube).
class _Resumen extends StatelessWidget {
  const _Resumen({
    required this.vm,
    required this.boton,
    required this.onCancelar,
  });

  final EntradaMercanciaViewModel vm;
  final Widget boton;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final producto = vm.producto;
    final unidad = producto == null
        ? ''
        : ' ${unidadCorta(producto.getUnidadMedida())}';
    final cantidad = vm.cantidad;
    final costo = vm.costo;
    return ResumenMovimiento(
      etiquetaAntes: 'Llegan',
      antes: cantidad == null ? '—' : '+ ${mostrarCantidad(cantidad)}',
      etiquetaDespues: 'Total de la compra',
      despues: _total(vm),
      conFlecha: false,
      detalles: [
        FilaDetalle('Producto', producto?.getNombre() ?? '—'),
        FilaDetalle(
          'Llegan',
          cantidad == null ? '—' : '+ ${mostrarCantidad(cantidad)}$unidad',
        ),
        FilaDetalle(
          'Costo por unidad',
          costo == null ? r'$ —' : '\$ ${mostrarPrecio(costo)}',
        ),
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
      ],
    );
  }
}
