import 'package:flutter/material.dart';
import 'package:gip/presentation/comun/barra_busqueda.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/tarjeta_accion.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/surtido/rutas_surtido.dart';

/// Sección Surtido (`docs/ui/rediseno/surtido-web.html` y `surtido-movil.html`):
/// "Producto nuevo" (CUS-18), la búsqueda (CUS-06) y las acciones Entrada de
/// mercancía (CUS-01) y Pérdida o devolución (CUS-03). La tabla de existencias
/// llega con CUS-25 y Conteo físico con CUS-04; mientras tanto la línea de
/// contexto es un texto fijo sin cifras (DI-23).
class SurtidoView extends StatelessWidget {
  const SurtidoView({super.key});

  static const contexto = 'Entradas, pérdidas y productos de la tienda';

  @override
  Widget build(BuildContext context) {
    final web = FormaGip.esWeb(context);
    final separacion = SizedBox(height: web ? 24 : 16);
    final acciones = [
      TarjetaAccion(
        key: const Key('surtido_registrar_entrada'),
        icono: Icons.south,
        titulo: web ? 'Registrar entrada' : 'Entrada',
        descripcion: 'Llegó mercancía del proveedor',
        vertical: !web,
        onTap: () => abrirEntradaMercancia(context),
      ),
      TarjetaAccion(
        key: const Key('surtido_registrar_perdida'),
        icono: Icons.trending_down,
        titulo: web ? 'Registrar pérdida' : 'Pérdida',
        descripcion: 'Vencido, dañado o devuelto',
        vertical: !web,
        onTap: () => abrirPerdida(context),
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
                  contexto: contexto,
                  accion: web
                      ? BotonPrimario(
                          texto: 'Producto nuevo',
                          icono: Icons.add,
                          compacto: true,
                          onPressed: () => abrirProductoNuevo(context),
                        )
                      : BotonIconoPrimario(
                          icono: Icons.add,
                          tooltip: 'Producto nuevo',
                          onPressed: () => abrirProductoNuevo(context),
                        ),
                ),
                separacion,
                BarraBusqueda(
                  key: const Key('surtido_buscar'),
                  pista: web
                      ? 'Buscar producto por nombre…'
                      : 'Buscar en el surtido…',
                  onTap: () => abrirBuscarProducto(context),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
