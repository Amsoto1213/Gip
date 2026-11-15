import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/surtido/entrada_mercancia_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:gip/presentation/surtido/widgets_movimiento.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla Entrada de mercancía (CUS-01, mockups `Entrada` y `wEntrada`).
///
/// El producto se elige en Buscar producto (CUS-06) en modo seleccionar; si la
/// pantalla abre sin producto, la búsqueda se abre sola. Sin "Hay N · último
/// costo" ni "Quedará en": el diseño no los entrega (DI-20).
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
    final ancho = MediaQuery.sizeOf(context).width >= 720;
    final margen = ancho ? 32.0 : 20.0;
    final boton = BotonRegistrarMovimiento(
      prefijoClave: 'entrada',
      texto: 'Registrar entrada',
      registrando: vm.registrando,
      onPressed: _registrar,
    );

    final formulario = _formulario(vm, ancho);
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ancho ? 1180 : 880),
            child: ancho
                ? ListView(
                    padding: EdgeInsets.fromLTRB(margen, 16, margen, 24),
                    children: [
                      EncabezadoSurtido(
                        titulo: 'Entrada de mercancía',
                        onVolver: _volver,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [formulario],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: _Resumen(vm: vm, boton: boton),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(margen, 16, margen, 24),
                          children: [
                            EncabezadoSurtido(
                              titulo: 'Entrada de mercancía',
                              onVolver: _volver,
                            ),
                            const SizedBox(height: 16),
                            formulario,
                          ],
                        ),
                      ),
                      BarraInferiorMovimiento(
                        margen: margen,
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

  Widget _formulario(EntradaMercanciaViewModel vm, bool ancho) {
    final tema = Theme.of(context);
    final habilitado = !vm.registrando;
    final etiqueta = tema.textTheme.titleSmall?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
    );

    final cantidad = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ancho ? 'Unidades que llegaron' : '¿Cuántas unidades llegaron?',
          style: etiqueta,
        ),
        const SizedBox(height: 8),
        SelectorCantidad(
          prefijoClave: 'entrada',
          controlador: _cantidad,
          habilitado: habilitado,
          onCambio: vm.cambiarCantidad,
          onSumar: _sumar,
        ),
      ],
    );
    final costo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Costo por unidad', style: etiqueta),
        const SizedBox(height: 8),
        TextField(
          key: const Key('entrada_costo'),
          controller: _costo,
          enabled: habilitado,
          onChanged: vm.cambiarCosto,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: tema.textTheme.titleLarge,
          decoration: const InputDecoration(prefixText: r'$ ', hintText: '0'),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ancho) ...[
          Text('Producto', style: etiqueta),
          const SizedBox(height: 8),
        ],
        TarjetaProductoMovimiento(
          prefijoClave: 'entrada',
          producto: vm.producto,
          detalle: 'Código ${vm.producto?.getCodigo()}',
          textoSinProducto: '¿Qué producto llegó?',
          habilitado: habilitado,
          onElegir: _elegirProducto,
        ),
        const SizedBox(height: 20),
        if (ancho)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cantidad),
              const SizedBox(width: 16),
              Expanded(child: costo),
            ],
          )
        else ...[
          cantidad,
          const SizedBox(height: 20),
          costo,
        ],
        if (vm.costoDifiere) ...[
          const SizedBox(height: 16),
          const _AdvertenciaCosto(),
        ],
        const SizedBox(height: 20),
        Text(
          ancho ? 'N.º de factura (opcional)' : 'N.º de factura (si la trae)',
          style: etiqueta,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('entrada_factura'),
          controller: _factura,
          enabled: habilitado,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: 'Ej.: FV-10231'),
        ),
      ],
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

/// Columna derecha en escritorio (`wEntrada`).
class _Resumen extends StatelessWidget {
  const _Resumen({required this.vm, required this.boton});

  final EntradaMercanciaViewModel vm;
  final Widget boton;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final unidad = vm.producto == null
        ? ''
        : ' ${unidadCorta(vm.producto!.getUnidadMedida())}';
    final cantidad = vm.cantidad;
    final costo = vm.costo;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resumen', style: tema.textTheme.titleLarge),
            const SizedBox(height: 12),
            FilaResumen(
              'Llegan',
              cantidad == null ? '—' : '+ ${mostrarCantidad(cantidad)}$unidad',
            ),
            FilaResumen(
              'Costo por unidad',
              costo == null ? r'$ —' : '\$ ${mostrarPrecio(costo)}',
            ),
            const Divider(),
            FilaResumen('Total de la compra', _total(vm), destacada: true),
            const SizedBox(height: 16),
            MensajesMovimiento(error: vm.error, aviso: vm.aviso),
            boton,
          ],
        ),
      ),
    );
  }
}
