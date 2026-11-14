import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/surtido/entrada_mercancia_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
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
    final boton = _BotonRegistrar(
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
                      _Encabezado(onVolver: _volver),
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
                            _Encabezado(onVolver: _volver),
                            const SizedBox(height: 16),
                            formulario,
                          ],
                        ),
                      ),
                      _BarraInferior(vm: vm, boton: boton, margen: margen),
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
        _SelectorCantidad(
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
        _TarjetaProducto(
          producto: vm.producto,
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

/// Cantidad como texto: sin miles y con coma decimal (2,5).
String mostrarCantidad(Decimal cantidad) =>
    cantidad.toString().replaceAll('.', ',');

String _unidadCorta(UnidadMedida unidad) => switch (unidad) {
  UnidadMedida.unidad => 'und',
  UnidadMedida.kilogramo => 'kg',
  UnidadMedida.libra => 'lb',
};

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.onVolver});

  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: onVolver,
          tooltip: 'Volver',
          iconSize: 28,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SURTIDO',
                style: tema.textTheme.labelMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  'Entrada de mercancía',
                  style: tema.textTheme.headlineLarge,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TarjetaProducto extends StatelessWidget {
  const _TarjetaProducto({
    required this.producto,
    required this.habilitado,
    required this.onElegir,
  });

  final Producto? producto;
  final bool habilitado;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final producto = this.producto;
    final boton = OutlinedButton(
      key: const Key('entrada_elegir_producto'),
      onPressed: habilitado ? onElegir : null,
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      child: Text(producto == null ? 'Elegir' : 'Cambiar'),
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tema.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: tema.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto?.getNombre() ?? '¿Qué producto llegó?',
                    style: tema.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    producto == null
                        ? 'Búsquelo por el nombre'
                        : 'Código ${producto.getCodigo()}',
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            boton,
          ],
        ),
      ),
    );
  }
}

class _SelectorCantidad extends StatelessWidget {
  const _SelectorCantidad({
    required this.controlador,
    required this.habilitado,
    required this.onCambio,
    required this.onSumar,
  });

  final TextEditingController controlador;
  final bool habilitado;
  final ValueChanged<String> onCambio;
  final ValueChanged<int> onSumar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    Widget paso(int valor, IconData icono, String ayuda) =>
        IconButton.filledTonal(
          key: Key('entrada_cantidad_${valor > 0 ? 'mas' : 'menos'}'),
          onPressed: habilitado ? () => onSumar(valor) : null,
          tooltip: ayuda,
          iconSize: 28,
          style: IconButton.styleFrom(
            minimumSize: const Size(56, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: Icon(icono),
        );
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        border: Border.all(color: tema.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          paso(-1, Icons.remove, 'Una menos'),
          Expanded(
            child: TextField(
              key: const Key('entrada_cantidad'),
              controller: controlador,
              enabled: habilitado,
              onChanged: onCambio,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: tema.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          paso(1, Icons.add, 'Una más'),
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

class _BotonRegistrar extends StatelessWidget {
  const _BotonRegistrar({required this.registrando, required this.onPressed});

  final bool registrando;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    key: const Key('entrada_registrar'),
    onPressed: registrando ? null : onPressed,
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
    icon: registrando
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : const Icon(Icons.check),
    label: const Text('Registrar entrada'),
  );
}

class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.valor, {this.destacada = false});

  final String etiqueta;
  final String valor;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estilo = destacada
        ? tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : tema.textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: estilo)),
          Text(
            valor,
            style: destacada
                ? tema.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  )
                : estilo,
          ),
        ],
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
        : ' ${_unidadCorta(vm.producto!.getUnidadMedida())}';
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
            _Fila(
              'Llegan',
              cantidad == null ? '—' : '+ ${mostrarCantidad(cantidad)}$unidad',
            ),
            _Fila(
              'Costo por unidad',
              costo == null ? r'$ —' : '\$ ${mostrarPrecio(costo)}',
            ),
            const Divider(),
            _Fila('Total de la compra', _total(vm), destacada: true),
            const SizedBox(height: 16),
            _Mensajes(vm: vm),
            boton,
          ],
        ),
      ),
    );
  }
}

/// Barra fija abajo en el teléfono (`Entrada`).
class _BarraInferior extends StatelessWidget {
  const _BarraInferior({
    required this.vm,
    required this.boton,
    required this.margen,
  });

  final EntradaMercanciaViewModel vm;
  final Widget boton;
  final double margen;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        border: Border(top: BorderSide(color: tema.colorScheme.outlineVariant)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(margen, 8, margen, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Mensajes(vm: vm),
            _Fila('Total de la compra', _total(vm), destacada: true),
            const SizedBox(height: 8),
            boton,
          ],
        ),
      ),
    );
  }
}

/// Error o aviso del último intento, junto al botón para que se vea siempre
/// (en el teléfono, el formulario puede quedar debajo del teclado).
class _Mensajes extends StatelessWidget {
  const _Mensajes({required this.vm});

  final EntradaMercanciaViewModel vm;

  @override
  Widget build(BuildContext context) {
    final error = vm.error;
    final aviso = vm.aviso;
    if (error == null && aviso == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: error != null
          ? _Mensaje(texto: error, esError: true)
          : _Mensaje(texto: aviso!, esError: false),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.texto, required this.esError});

  final String texto;
  final bool esError;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final fondo = esError ? esquema.errorContainer : esquema.primaryContainer;
    final color = esError ? esquema.error : esquema.onPrimaryContainer;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              esError ? Icons.warning_amber_rounded : Icons.check_circle,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
