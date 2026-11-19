import 'package:flutter/material.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/pantalla_seccion.dart';
import 'package:gip/presentation/comun/tarjeta_accion.dart';
import 'package:gip/presentation/comun/tema/forma_gip.dart';
import 'package:gip/presentation/negocio/rutas_negocio.dart';
import 'package:provider/provider.dart';

/// Sección Negocio (pendiente: ver `docs/ui/pantallas.md`). Por ahora tiene
/// Alertas de surtido (CUS-05), Reporte del día (CUS-10), Ganancia por
/// producto (CUS-09), Rotación de productos (CUS-12), Usuarios (CUS-15),
/// Exportar datos (CUS-16) y "Cerrar sesión" (DI-05); al salir, el router
/// vuelve al acceso.
class NegocioView extends StatelessWidget {
  const NegocioView({super.key});

  @override
  Widget build(BuildContext context) {
    final web = FormaGip.esWeb(context);
    return PantallaSeccion(
      titulo: 'Negocio',
      hijos: [
        SizedBox(height: web ? 24 : 16),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: TarjetaAccion(
              key: const Key('negocio_alertas'),
              icono: Icons.notifications_none,
              titulo: 'Alertas de surtido',
              descripcion: 'Lo que está por agotarse',
              onTap: () => abrirAlertas(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: TarjetaAccion(
              key: const Key('negocio_reporte'),
              icono: Icons.receipt_long_outlined,
              titulo: 'Reporte del día',
              descripcion: 'Lo que vendió y ganó hoy',
              onTap: () => abrirReporte(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: TarjetaAccion(
              key: const Key('negocio_ganancia'),
              icono: Icons.trending_up,
              titulo: 'Ganancia por producto',
              descripcion: 'Cuánto deja cada producto',
              onTap: () => abrirMargen(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: TarjetaAccion(
              key: const Key('negocio_rotacion'),
              icono: Icons.swap_vert,
              titulo: 'Rotación de productos',
              descripcion: 'Lo que más y lo que menos se vende',
              onTap: () => abrirRotacion(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: TarjetaAccion(
              key: const Key('negocio_usuarios'),
              icono: Icons.group_outlined,
              titulo: 'Usuarios',
              descripcion: 'Quién puede entrar a la tienda',
              onTap: () => abrirUsuarios(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: TarjetaAccion(
              key: const Key('negocio_exportar'),
              icono: Icons.file_download_outlined,
              titulo: 'Exportar datos',
              descripcion: 'Inventario, ventas y fiados en Excel o CSV',
              onTap: () => abrirExportar(context),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: BotonSecundario(
            key: const Key('negocio_cerrar_sesion'),
            texto: 'Cerrar sesión',
            icono: Icons.logout,
            onPressed: () =>
                context.read<IniciarSesionViewModel>().cerrarSesion(),
          ),
        ),
      ],
    );
  }
}
