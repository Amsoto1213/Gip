import 'package:flutter/material.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/presentation/comun/barra_busqueda.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/icono_paquete.dart';
import 'package:gip/presentation/comun/leer_codigo.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/surtido/buscar_producto_view_model.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Agrega a la ruta de Buscar producto (de Surtido o de Vender) el pedido de
/// abrir la cámara al entrar (atajo del botón del lector, CUS-17).
String conCamara(String rutaBuscar) => '$rutaBuscar?camara=1';

/// Verdadero si la ruta de Buscar producto pide abrir la cámara.
bool pideCamara(GoRouterState state) =>
    state.uri.queryParameters['camara'] == '1';

/// Qué pasa al tocar un resultado de la búsqueda.
enum ModoBusqueda {
  /// Abre el producto para editarlo (CUS-18).
  editar,

  /// Cierra la búsqueda y devuelve el producto a quien la abrió (por ejemplo,
  /// Entrada de mercancía, CUS-01).
  seleccionar,
}

/// Pantalla Buscar producto (CUS-06, mockup `mBuscar`): por nombre y por
/// lectura de código (CUS-17). Por ahora vive en Surtido. Según [modo], al
/// tocar un resultado, o al leer el código de un producto, abre el producto
/// para editarlo (CUS-18) o lo devuelve con `pop` (CUS-01, DI-20).
///
/// El lector 2D en modo teclado escribe en el campo y oprime Enter; en la app
/// Android el botón del lector abre la cámara (DI-34). Las existencias,
/// "Agregar" y "Anotar que se fue sin él" no están aquí (DI-19).
class BuscarProductoView extends StatefulWidget {
  const BuscarProductoView({
    super.key,
    this.modo = ModoBusqueda.editar,
    this.seccion = 'Surtido',
    this.abrirCamara = false,
  });

  final ModoBusqueda modo;

  /// Sección desde la que se abrió, para la miga y el botón de volver.
  final String seccion;

  /// Si es verdadero, la cámara se abre al entrar (atajo del botón del lector
  /// de Vender y Surtido).
  final bool abrirCamara;

  @override
  State<BuscarProductoView> createState() => _BuscarProductoViewState();
}

class _BuscarProductoViewState extends State<BuscarProductoView> {
  final _texto = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.abrirCamara && camaraDisponible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _leerConCamara());
    }
  }

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

  /// Lectura del lector 2D en modo teclado (o un código escrito) al oprimir
  /// Enter (CUS-17, pasos 1, 2 y 7).
  Future<void> _leer(String lectura) async {
    final producto = await context
        .read<BuscarProductoViewModel>()
        .buscarPorLectura(lectura);
    if (producto != null && mounted) await _tocarResultado(producto);
  }

  /// Lectura con la cámara del celular (CUS-17, pasos 3 a 5 y 7).
  Future<void> _leerConCamara() async {
    final vm = context.read<BuscarProductoViewModel>();
    final resultado = await leerCodigoConCamara(context);
    if (!mounted) return;
    switch (resultado) {
      case null:
        return;
      case LecturaFallida():
        vm.lecturaFallida();
      case LecturaLeida(:final texto):
        _texto.text = texto.trim();
        final producto = await vm.buscarPorLectura(texto, desdeCamara: true);
        if (producto != null && mounted) await _tocarResultado(producto);
    }
  }

  /// Abre Producto para crear uno nuevo. Con [codigo] (leído y no
  /// registrado) el producto nuevo lo lleva asociado (CUS-17 → CUS-18); al
  /// volver se busca otra vez ese código y, si quien abrió la búsqueda espera
  /// un producto, se le devuelve el recién creado.
  Future<void> _crear({String? codigo}) async {
    final vm = context.read<BuscarProductoViewModel>();
    await abrirProductoNuevo(context, codigoLeido: codigo);
    if (!mounted) return;
    if (codigo == null) {
      await vm.repetirBusqueda();
      return;
    }
    _texto.text = codigo;
    final producto = await vm.buscarPorLectura(codigo, desdeCamara: true);
    if (producto != null &&
        mounted &&
        widget.modo == ModoBusqueda.seleccionar) {
      context.pop(producto);
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
      onSubmitted: _leer,
      onLeerCodigo: camaraDisponible ? _leerConCamara : null,
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
    final avisoLectura = vm.avisoLectura;
    return [
      if (avisoLectura != null) ...[
        _Aviso(
          key: const Key('buscar_aviso_lectura'),
          texto: avisoLectura,
          esError: true,
        ),
        const SizedBox(height: 16),
      ],
      ..._resultados(vm, secundario),
    ];
  }

  List<Widget> _resultados(BuscarProductoViewModel vm, TextStyle? secundario) {
    switch (vm.estado) {
      case EstadoBusqueda.inicial:
        return [
          Text(
            'Escriba el nombre del producto o lea su código · sin tildes ni '
            'mayúsculas · funciona sin internet',
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
        final codigo = vm.codigoNoRegistrado;
        return [
          _Aviso(
            texto: BuscarProductoViewModel.mensajeSinCoincidencias,
            detalle: codigo == null ? null : 'Código leído: $codigo',
            esError: false,
            accion: BotonPrimario(
              key: const Key('buscar_crear_sin_coincidencias'),
              texto: codigo == null
                  ? 'Crear producto'
                  : 'Crear producto con este código',
              icono: Icons.add,
              compacto: true,
              onPressed: () => _crear(codigo: codigo),
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
  const _Aviso({
    super.key,
    required this.texto,
    required this.esError,
    this.detalle,
    this.accion,
  });

  final String texto;
  final bool esError;

  /// Línea debajo del texto (p. ej. el código leído).
  final String? detalle;
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
            if (detalle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  detalle!,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: color)
                      .cifrasTabulares,
                ),
              ),
            ],
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
