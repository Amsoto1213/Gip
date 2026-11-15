import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/presentation/comun/barra_busqueda.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/icono_paquete.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
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
  const BuscarProductoView({
    super.key,
    this.modo = ModoBusqueda.editar,
    this.seccion = 'Surtido',
  });

  final ModoBusqueda modo;

  /// Sección desde la que se abrió, para la miga y el botón de volver.
  final String seccion;

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
    final web = FormaGip.esWeb(context);
    final margen = web ? 44.0 : 16.0;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 968),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    margen,
                    web ? 32 : 16,
                    margen,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EncabezadoPantalla(
                        titulo: 'Buscar producto',
                        seccion: widget.seccion,
                        onVolver: _volver,
                      ),
                      SizedBox(height: web ? 24 : 16),
                      _campoBusqueda(),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(margen, 16, margen, 16),
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
    builder: (context, valor, _) => BarraBusqueda(
      pista: 'Nombre del producto',
      controlador: _texto,
      campoKey: const Key('buscar_texto'),
      autofocus: true,
      onChanged: context.read<BuscarProductoViewModel>().buscar,
      sufijo: valor.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Borrar',
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: _borrar,
              icon: const Icon(Icons.close),
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
            accion: BotonPrimario(
              key: const Key('buscar_crear_sin_coincidencias'),
              texto: 'Crear producto',
              icono: Icons.add,
              compacto: true,
              onPressed: _crear,
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
    return TarjetaGip(
      child: Column(
        children: [
          for (var i = 0; i < productos.length; i++) ...[
            if (i > 0) const Divider(),
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
    final extra = tema.extension<ColoresExtraGip>()!;
    final esquema = tema.colorScheme;
    return InkWell(
      onTap: onTap,
      hoverColor: extra.superficieSuave,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tema.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
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
                      style: tema.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$ ${mostrarPrecio(producto.getPrecioVenta())}'
                      '${_porUnidad(producto.getUnidadMedida())}',
                      style: tema.textTheme.bodySmall
                          ?.copyWith(fontSize: 13)
                          .cifrasTabulares,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: esquema.onSurfaceVariant,
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
        Text(
          '¿No lo encuentra?',
          style: tema.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'Créelo y quedará en el catálogo.',
          style: tema.textTheme.bodyMedium?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    final boton = BotonSecundario(
      key: const Key('buscar_crear_producto'),
      texto: 'Crear producto',
      icono: Icons.add,
      onPressed: onCrear,
    );
    return TarjetaGip(
      radio: FormaGip.radioTarjetaAccion,
      padding: const EdgeInsets.all(18),
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
