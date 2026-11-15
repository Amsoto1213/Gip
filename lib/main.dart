import 'package:flutter/material.dart';
import 'package:gip/business/workflow/gestion_inventario/buscar_producto_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/gestionar_producto_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_entrada_mercancia_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_perdida_coordinator.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_venta_coordinator.dart';
import 'package:gip/composition_root/registrar_acceso.dart';
import 'package:gip/composition_root/registrar_caja.dart';
import 'package:gip/composition_root/registrar_inventario.dart';
import 'package:gip/composition_root/registrar_pagos.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/service_agents/cliente_supabase.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/router.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/transversal/configuracion/configuracion_supabase.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Composition Root del GIP: único lugar que conoce las clases concretas de data/.
/// Los módulos se registran desde composition_root/.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cliente = await ClienteSupabase(
    const ConfiguracionSupabase.desdeEntorno(),
  ).inicializar();
  final base = BaseLocalDrift.abrir();
  final unidadTrabajo = UnidadTrabajoDrift(base);
  final inventario = registrarInventario(base, unidadTrabajo);
  final caja = registrarCaja(base);
  final pagos = registrarPagos(
    base,
    unidadTrabajo,
    inventario.servicioInventario,
    caja.servicioCaja,
  );
  runApp(
    GipApp(
      iniciarSesion: registrarAcceso(cliente),
      gestionarProducto: inventario.gestionarProducto,
      buscarProducto: inventario.buscarProducto,
      registrarEntradaMercancia: inventario.registrarEntradaMercancia,
      registrarPerdida: inventario.registrarPerdida,
      registrarVenta: pagos.registrarVenta,
    ),
  );
}

class GipApp extends StatefulWidget {
  const GipApp({
    super.key,
    required this.iniciarSesion,
    required this.gestionarProducto,
    required this.buscarProducto,
    required this.registrarEntradaMercancia,
    required this.registrarPerdida,
    required this.registrarVenta,
  });

  final IniciarSesionCoordinator iniciarSesion;
  final GestionarProductoCoordinator gestionarProducto;
  final BuscarProductoCoordinator buscarProducto;
  final RegistrarEntradaMercanciaCoordinator registrarEntradaMercancia;
  final RegistrarPerdidaCoordinator registrarPerdida;
  final RegistrarVentaCoordinator registrarVenta;

  @override
  State<GipApp> createState() => _GipAppState();
}

class _GipAppState extends State<GipApp> {
  late final IniciarSesionViewModel _sesion = IniciarSesionViewModel(
    widget.iniciarSesion,
  )..verificarSesionGuardada();
  late final GoRouter _router = crearRouter(_sesion);

  @override
  void dispose() {
    _router.dispose();
    _sesion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _sesion),
        Provider.value(value: widget.gestionarProducto),
        Provider.value(value: widget.buscarProducto),
        Provider.value(value: widget.registrarEntradaMercancia),
        Provider.value(value: widget.registrarPerdida),
        Provider.value(value: widget.registrarVenta),
      ],
      child: MaterialApp.router(
        title: 'GIP',
        theme: TemaGip.claro(),
        routerConfig: _router,
      ),
    );
  }
}
