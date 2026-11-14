import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/tema/colores_gip.dart';
import 'package:gip/presentation/surtido/buscar_producto_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Qué pasa al tocar un resultado de la búsqueda.
enum ModoBusqueda {
  /// Abre el producto para editarlo (CUS-18).
  editar,

  /// Cierra la búsqueda y devuelve el producto a quien la abrió (por ejemplo,
  /// Entrada de mercancía, CUS-01).
  seleccionar,
}

/// Pantalla Buscar producto (CUS-06, mockup `mBuscar`), solo la búsqueda por
/// nombre. Por ahora vive en Surtido. Según [modo], al tocar un resultado abre
/// el producto para editarlo (CUS-18) o lo devuelve con `pop` (CUS-01, DI-20).
/// Las existencias, "Agregar", "Anotar que se fue sin él" y el botón del
/// lector llegan con CUS-25, CUS-02, CUS-13 y CUS-17 (DI-19).
class BuscarProductoView extends StatefulWidget {
  const BuscarProductoView({super.key, this.modo = ModoBusqueda.editar});

  final ModoBusqueda modo;

  @override
  State<BuscarProductoView> createState() => _BuscarProductoViewState();
}

class _BuscarProductoViewState extends State<BuscarProductoView> {
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _borrar() {
    _texto.clear();
    context.read<BuscarProductoViewModel>().buscar('');
  }

  Future<void> _tocarResultado(Producto producto) async {
    if (widget.modo == ModoBusqueda.seleccionar) {
      context.pop(producto);
      return;
    }
    final vm = context.read<BuscarProductoViewModel>();
    await abrirProductoParaEditar(context, producto);
    await vm.repetirBusqueda();
  }

  Future<void> _crear() async {
    final vm = context.read<BuscarProductoViewModel>();
    await abrirProductoNuevo(context);
    await vm.repetirBusqueda();
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
    final vm = context.watch<BuscarProductoViewModel>();
    final ancho = MediaQuery.sizeOf(context).width >= 720;
    final margen = ancho ? 32.0 : 20.0;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(margen, 16, margen, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Encabezado(onVolver: _volver),
                      const SizedBox(height: 16),
                      _campoBusqueda(),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(margen, 12, margen, 16),
                    children: _contenido(vm),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(margen, 0, margen, 16),
                  child: _NoLoEncuentra(onCrear: _crear),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoBusqueda() => ValueListenableBuilder(
    valueListenable: _texto,
    builder: (context, valor, _) => TextField(
      key: const Key('buscar_texto'),
      controller: _texto,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onChanged: context.read<BuscarProductoViewModel>().buscar,
      decoration: InputDecoration(
        hintText: 'Nombre del producto',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: valor.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Borrar',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: _borrar,
                icon: const Icon(Icons.close),
              ),
      ),
    ),
  );

  List<Widget> _contenido(BuscarProductoViewModel vm) {
    final tema = Theme.of(context);
    final secundario = tema.textTheme.bodyMedium?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
    );

    if (vm.error != null) {
      return [_Aviso(texto: vm.error!, esError: true)];
    }
    switch (vm.estado) {
      case EstadoBusqueda.inicial:
        return [
          Text(
            'Escriba el nombre del producto · sin tildes ni mayúsculas · '
            'funciona sin internet',
            style: secundario,
          ),
        ];
      case EstadoBusqueda.buscando when vm.productos.isEmpty:
        return const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case EstadoBusqueda.sinCoincidencias:
        return [
          _Aviso(
            texto: BuscarProductoViewModel.mensajeSinCoincidencias,
            esError: false,
            accion: FilledButton.icon(
              key: const Key('buscar_crear_sin_coincidencias'),
              onPressed: _crear,
              icon: const Icon(Icons.add),
              label: const Text('Crear producto'),
            ),
          ),
        ];
      case EstadoBusqueda.buscando:
      case EstadoBusqueda.conResultados:
        final n = vm.productos.length;
        return [
          Text(
            '$n ${n == 1 ? 'resultado' : 'resultados'} · sin tildes ni '
            'mayúsculas · funciona sin internet',
            style: secundario,
          ),
          const SizedBox(height: 12),
          _ListaResultados(
            productos: vm.productos,
            onSeleccionar: _tocarResultado,
            accion: widget.modo == ModoBusqueda.seleccionar
                ? 'Elegir'
                : 'Editar',
          ),
        ];
    }
  }
}

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
                  'Buscar producto',
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

class _ListaResultados extends StatelessWidget {
  const _ListaResultados({
    required this.productos,
    required this.onSeleccionar,
    required this.accion,
  });

  final List<Producto> productos;
  final ValueChanged<Producto> onSeleccionar;

  /// Etiqueta para el lector de pantalla de la flecha de cada fila.
  final String accion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < productos.length; i++) ...[
            if (i > 0) Divider(height: 1, color: extra.separador),
            _FilaProducto(
              producto: productos[i],
              accion: accion,
              onTap: () => onSeleccionar(productos[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaProducto extends StatelessWidget {
  const _FilaProducto({
    required this.producto,
    required this.accion,
    required this.onTap,
  });

  final Producto producto;
  final String accion;
  final VoidCallback onTap;

  static String _porUnidad(UnidadMedida unidad) => switch (unidad) {
    UnidadMedida.unidad => '',
    UnidadMedida.kilogramo => ' el kilo',
    UnidadMedida.libra => ' la libra',
  };

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.getNombre(),
                      style: tema.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$ ${mostrarPrecio(producto.getPrecioVenta())}'
                      '${_porUnidad(producto.getUnidadMedida())}',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: tema.colorScheme.onSurfaceVariant,
                semanticLabel: accion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, required this.esError, this.accion});

  final String texto;
  final bool esError;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final extra = Theme.of(context).extension<ColoresExtraGip>()!;
    final fondo = esError ? esquema.errorContainer : extra.info;
    final color = esError ? esquema.error : extra.infoTexto;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  esError ? Icons.warning_amber_rounded : Icons.info_outline,
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
            if (accion != null) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: accion),
            ],
          ],
        ),
      ),
    );
  }
}

/// Recuadro fijo del mockup: "¿No lo encuentra? Crear producto".
class _NoLoEncuentra extends StatelessWidget {
  const _NoLoEncuentra({required this.onCrear});

  final VoidCallback onCrear;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿No lo encuentra?', style: tema.textTheme.titleSmall),
        Text(
          'Créelo y quedará en el catálogo.',
          style: tema.textTheme.bodyMedium?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    final boton = OutlinedButton.icon(
      key: const Key('buscar_crear_producto'),
      onPressed: onCrear,
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      icon: const Icon(Icons.add),
      label: const Text('Crear producto'),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: tema.colorScheme.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      // En pantallas angostas (5") el botón va debajo del texto.
      child: LayoutBuilder(
        builder: (context, limites) => limites.maxWidth >= 480
            ? Row(
                children: [
                  Expanded(child: textos),
                  const SizedBox(width: 12),
                  boton,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [textos, const SizedBox(height: 12), boton],
              ),
      ),
    );
  }
}
