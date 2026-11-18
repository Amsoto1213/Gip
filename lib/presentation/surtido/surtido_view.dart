import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/leer_codigo.dart';
import 'package:gip/presentation/comun/barra_busqueda.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/tarjeta_accion.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/surtido/existencias_view_model.dart';
import 'package:gip/presentation/surtido/lista_existencias.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';
import 'package:provider/provider.dart';

/// Sección Surtido (`docs/ui/rediseno/surtido-web.html` y `surtido-movil.html`):
/// "Producto nuevo" (CUS-18), la búsqueda (CUS-06), las acciones Entrada de
/// mercancía (CUS-01), Pérdida o devolución (CUS-03) y Conteo físico (CUS-04),
/// y las existencias (CUS-25) con [ExistenciasViewModel].
///
/// La lista se recarga al volver de una acción y al volver a la pestaña
/// (DI-32): una venta en Vender cambia las existencias.
class SurtidoView extends StatefulWidget {
  const SurtidoView({super.key, this.reloj});

  /// Línea de contexto mientras la lista no ha cargado.
  static const contexto =
      'Entradas, pérdidas, conteos y productos de la tienda';

  /// Para las pruebas: el momento de "Hoy" y "Ayer".
  final DateTime Function()? reloj;

  /// "128 productos" (sin el valor del inventario, DI-32).
  static String contextoConProductos(int total) =>
      total == 1 ? '1 producto' : '$total productos';

  @override
  State<SurtidoView> createState() => _SurtidoViewState();
}

class _SurtidoViewState extends State<SurtidoView> {
  bool? _visible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // La pestaña inactiva queda con TickerMode apagado (StatefulShellRoute).
    final visible = TickerMode.valuesOf(context).enabled;
    if (_visible == false && visible) {
      // Se está construyendo: cargar() notifica, así que va después del cuadro.
      final vm = context.read<ExistenciasViewModel>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) vm.cargar();
      });
    }
    _visible = visible;
  }

  /// Abre la pantalla y, al volver, recarga las existencias.
  Future<void> _abrir(Future<void> Function(BuildContext) abrir) async {
    await abrir(context);
    if (mounted) await context.read<ExistenciasViewModel>().cargar();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExistenciasViewModel>();
    final web = FormaGip.esWeb(context);
    final ahora = (widget.reloj ?? DateTime.now)();
    final separacion = SizedBox(height: web ? 24 : 16);
    final acciones = [
      TarjetaAccion(
        key: const Key('surtido_registrar_entrada'),
        icono: Icons.south,
        titulo: web ? 'Registrar entrada' : 'Entrada',
        descripcion: 'Llegó mercancía del proveedor',
        vertical: !web,
        onTap: () => _abrir(abrirEntradaMercancia),
      ),
      TarjetaAccion(
        key: const Key('surtido_registrar_perdida'),
        icono: Icons.trending_down,
        titulo: web ? 'Registrar pérdida' : 'Pérdida',
        descripcion: 'Vencido, dañado o devuelto',
        vertical: !web,
        onTap: () => _abrir(abrirPerdida),
      ),
      TarjetaAccion(
        key: const Key('surtido_conteo'),
        icono: Icons.fact_check_outlined,
        titulo: web ? 'Conteo físico' : 'Conteo',
        descripcion: 'Cuente y corrija la existencia',
        vertical: !web,
        onTap: () => _abrir(abrirConteo),
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: ListView(
              padding: web
                  ? const EdgeInsets.fromLTRB(44, 36, 44, 48)
                  : const EdgeInsets.fromLTRB(16, 28, 16, 24),
              children: [
                EncabezadoPantalla(
                  titulo: 'Surtido',
                  contexto: vm.cargado
                      ? SurtidoView.contextoConProductos(vm.total)
                      : SurtidoView.contexto,
                  accion: web
                      ? BotonPrimario(
                          texto: 'Producto nuevo',
                          icono: Icons.add,
                          compacto: true,
                          onPressed: () => _abrir(abrirProductoNuevo),
                        )
                      : BotonIconoPrimario(
                          icono: Icons.add,
                          tooltip: 'Producto nuevo',
                          onPressed: () => _abrir(abrirProductoNuevo),
                        ),
                ),
                separacion,
                BarraBusqueda(
                  key: const Key('surtido_buscar'),
                  pista: web
                      ? 'Buscar producto por nombre…'
                      : 'Buscar en el surtido…',
                  onTap: () => _abrir(abrirBuscarProducto),
                  onLeerCodigo: camaraDisponible
                      ? () => _abrir(leerCodigoEnSurtido)
                      : null,
                ),
                separacion,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < acciones.length; i++) ...[
                      if (i > 0) SizedBox(width: web ? 16 : 10),
                      Expanded(child: acciones[i]),
                    ],
                  ],
                ),
                separacion,
                if (!web && vm.cargado) ...[
                  FiltrosExistencias(vm: vm),
                  const SizedBox(height: 12),
                ],
                ListaExistencias(vm: vm, web: web, ahora: ahora),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
