import 'package:flutter/material.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/leer_codigo.dart';
import 'package:gip/presentation/comun/barra_busqueda.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/formato_pesos.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/vender/rutas_vender.dart';
import 'package:gip/presentation/vender/vender_view_model.dart';
import 'package:provider/provider.dart';

/// Pantalla Vender (CUS-02, mockup `Main`, con los componentes del
/// rediseño): buscar producto, venta actual y
/// "Cobrar". Sin "Lo más vendido", existencias, lector ni aviso de
/// sincronización todavía (DI-21).
class VenderView extends StatelessWidget {
  const VenderView({super.key});

  /// Abre Buscar producto (CUS-06) y agrega lo elegido. Con [camara] la
  /// búsqueda abre la cámara al entrar (botón del lector, CUS-17).
  Future<void> _buscar(BuildContext context, {bool camara = false}) async {
    final vm = context.read<VenderViewModel>();
    final producto = await elegirProductoParaVender(context, camara: camara);
    if (producto != null) await vm.agregar(producto);
  }

  Future<void> _cobrar(BuildContext context) async {
    final vm = context.read<VenderViewModel>();
    final registrada = await abrirCobrar(context, (
      lineas: vm.lineas,
      total: vm.total,
    ));
    if (registrada) vm.ventaRegistrada();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VenderViewModel>();
    final nombre = context.select<IniciarSesionViewModel, String?>(
      (s) => s.usuarioActivo?.usuario.getNombre(),
    );
    final web = FormaGip.esWeb(context);
    final margen = web ? 44.0 : 16.0;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 968),
            child: ListView(
              padding: EdgeInsets.fromLTRB(margen, web ? 36 : 28, margen, 24),
              children: [
                EncabezadoPantalla(
                  titulo: 'Vender',
                  contexto: nombre == null ? null : 'Hola, $nombre',
                ),
                SizedBox(height: web ? 24 : 16),
                BarraBusqueda(
                  key: const Key('vender_buscar'),
                  pista: 'Buscar producto…',
                  onTap: () => _buscar(context),
                  onLeerCodigo: camaraDisponible
                      ? () => _buscar(context, camara: true)
                      : null,
                ),
                if (vm.error != null) ...[
                  const SizedBox(height: 12),
                  _Mensaje(texto: vm.error!, esError: true),
                  if (vm.productoSinExistencia != null) ...[
                    const SizedBox(height: 8),
                    BotonSecundario(
                      key: const Key('vender_anotar_perdida'),
                      texto: 'Anotar que se fue sin él',
                      icono: Icons.edit_note,
                      expandido: true,
                      onPressed: vm.registrarVentaPerdida,
                    ),
                  ],
                ],
                if (vm.aviso != null) ...[
                  const SizedBox(height: 12),
                  _Mensaje(texto: vm.aviso!, esError: false),
                ],
                SizedBox(height: web ? 24 : 16),
                _VentaActual(vm: vm),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 968),
            child: Padding(
              padding: EdgeInsets.fromLTRB(margen, 8, margen, 12),
              child: BotonPrimario(
                key: const Key('vender_cobrar'),
                texto: 'Cobrar',
                valor: '\$ ${mostrarPrecio(vm.total)}',
                onPressed: vm.hayLineas ? () => _cobrar(context) : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta "Venta actual · N productos" con sus líneas y "Vaciar".
class _VentaActual extends StatelessWidget {
  const _VentaActual({required this.vm});

  final VenderViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final n = vm.lineas.length;
    return TarjetaGip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Venta actual',
                      style: tema.textTheme.titleLarge,
                      children: [
                        TextSpan(
                          text: ' · $n ${n == 1 ? 'producto' : 'productos'}',
                          style: tema.textTheme.bodyMedium?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (vm.hayLineas)
                  BotonSecundario(
                    key: const Key('vender_vaciar'),
                    texto: 'Vaciar',
                    sinBorde: true,
                    onPressed: vm.vaciar,
                  )
                else
                  const SizedBox(height: 48),
              ],
            ),
          ),
          const Divider(),
          if (!vm.hayLineas)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tema.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        FormaGip.radioCajaIcono,
                      ),
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Busque un producto para empezar la venta',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyLarge?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final (i, linea) in vm.lineas.indexed) ...[
              if (i > 0) const Divider(),
              _FilaLinea(
                linea: linea,
                onSumar: () => vm.sumar(linea),
                onRestar: () => vm.restar(linea),
              ),
            ],
        ],
      ),
    );
  }
}

class _FilaLinea extends StatelessWidget {
  const _FilaLinea({
    required this.linea,
    required this.onSumar,
    required this.onRestar,
  });

  final LineaVenta linea;
  final VoidCallback onSumar;
  final VoidCallback onRestar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final extra = tema.extension<ColoresExtraGip>()!;
    final producto = linea.getItem().getProducto();
    final id = producto.getId();
    final numero = tema.textTheme.headlineMedium
        ?.copyWith(fontSize: 18)
        .cifrasTabulares;
    Widget paso(String sufijo, IconData icono, String ayuda, VoidCallback f) =>
        IconButton(
          key: Key('vender_${sufijo}_$id'),
          onPressed: f,
          tooltip: ayuda,
          style: IconButton.styleFrom(
            fixedSize: const Size.square(44),
            backgroundColor: extra.pasoFondo,
            foregroundColor: tema.colorScheme.onSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(icono, size: 20),
        );
    final nombre = Text(
      producto.getNombre(),
      style: tema.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    );
    final precio = Text(
      '\$ ${mostrarPrecio(producto.getPrecioVenta())} c/u',
      style: tema.textTheme.bodySmall?.copyWith(fontSize: 13).cifrasTabulares,
    );
    final selector = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        paso('menos', Icons.remove, 'Quitar uno', onRestar),
        SizedBox(
          width: 44,
          child: Text(
            mostrarPrecio(linea.getCantidad()),
            key: Key('vender_cantidad_$id'),
            textAlign: TextAlign.center,
            style: numero,
          ),
        ),
        paso('mas', Icons.add, 'Agregar uno', onSumar),
      ],
    );
    final subtotal = Text(
      '\$ ${mostrarPrecio(linea.calcularSubtotal())}',
      textAlign: TextAlign.end,
      style: numero,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // En un teléfono, dos renglones: nombre y subtotal arriba, precio y
      // cantidad abajo, para que el nombre no se parta.
      child: LayoutBuilder(
        builder: (context, restricciones) => restricciones.maxWidth < 480
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: nombre),
                      const SizedBox(width: 12),
                      subtotal,
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: precio),
                      selector,
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [nombre, const SizedBox(height: 2), precio],
                    ),
                  ),
                  selector,
                  SizedBox(width: 110, child: subtotal),
                ],
              ),
      ),
    );
  }
}

/// Aviso o error en línea, con los colores del tema.
class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.texto, required this.esError});

  final String texto;
  final bool esError;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: esError ? esquema.errorContainer : esquema.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            esError ? Icons.error_outline : Icons.check_circle_outline,
            color: esError ? esquema.error : esquema.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: esError
                    ? esquema.onErrorContainer
                    : esquema.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
