import 'package:flutter/material.dart';
import 'package:gip/business/workflow/gestion_caja/consultar_margen_coordinator.dart';
import 'package:gip/business/workflow/gestion_caja/consultar_rotacion_coordinator.dart';
import 'package:gip/business/workflow/info_tienda/exportar_datos_coordinator.dart';
import 'package:gip/business/workflow/info_tienda/gestionar_usuarios_coordinator.dart';
import 'package:gip/business/workflow/gestion_caja/generar_reporte_diario_coordinator.dart';
import 'package:gip/business/workflow/gestion_caja/registrar_cierre_caja_coordinator.dart';
import 'package:gip/business/workflow/gestion_caja/registrar_movimiento_caja_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/buscar_producto_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/consultar_alertas_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/generar_alertas_diarias_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/gestionar_producto_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_entrada_mercancia_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/consultar_existencias_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_conteo_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_perdida_coordinator.dart';
import 'package:gip/business/workflow/gestion_inventario/registrar_venta_perdida_coordinator.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/business/workflow/pagos/anular_venta_coordinator.dart';
import 'package:gip/business/workflow/pagos/consultar_cliente_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_abono_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_fiado_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_venta_coordinator.dart';
import 'package:gip/composition_root/registrar_acceso.dart';
import 'package:gip/composition_root/registrar_alertas.dart';
import 'package:gip/composition_root/registrar_caja.dart';
import 'package:gip/composition_root/registrar_exportacion.dart';
import 'package:gip/composition_root/registrar_inventario.dart';
import 'package:gip/composition_root/registrar_pagos.dart';
import 'package:gip/composition_root/registrar_reportes.dart';
import 'package:gip/composition_root/registrar_usuarios.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/service_agents/cliente_supabase.dart';
import 'package:gip/presentation/acceso/iniciar_sesion_view_model.dart';
import 'package:gip/presentation/comun/idioma_gip.dart';
import 'package:gip/presentation/comun/router.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/negocio/disparador_alertas_diarias.dart';
import 'package:gip/transversal/configuracion/configuracion_supabase.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Composition Root del GIP: único lugar que conoce las clases concretas de data/.
/// Los módulos se registran desde composition_root/.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const configuracion = ConfiguracionSupabase.desdeEntorno();
  final cliente = await ClienteSupabase(configuracion).inicializar();
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
  final acceso = registrarAcceso(cliente);
  final cajaPropietario = registrarCoordinadoresCaja(
    caja.servicioCaja,
    acceso.servicioAcceso,
  );
  final anularVenta = registrarAnularVenta(
    pagos.servicioVentas,
    acceso.servicioAcceso,
  );
  final alertas = registrarAlertas(base, acceso.servicioAcceso);
  final reportes = registrarReportes(base, acceso.servicioAcceso);
  final exportarDatos = registrarExportacion(base, acceso.servicioAcceso);
  final gestionarUsuarios = registrarUsuarios(
    cliente,
    configuracion,
    acceso.servicioAcceso,
  );
  runApp(
    GipApp(
      iniciarSesion: acceso.iniciarSesion,
      gestionarProducto: inventario.gestionarProducto,
      buscarProducto: inventario.buscarProducto,
      registrarEntradaMercancia: inventario.registrarEntradaMercancia,
      registrarPerdida: inventario.registrarPerdida,
      registrarConteo: inventario.registrarConteo,
      consultarExistencias: inventario.consultarExistencias,
      registrarVenta: pagos.registrarVenta,
      registrarFiado: pagos.registrarFiado,
      registrarAbono: pagos.registrarAbono,
      consultarCliente: pagos.consultarCliente,
      generarAlertas: alertas.generarAlertas,
      consultarAlertas: alertas.consultarAlertas,
      registrarVentaPerdida: alertas.registrarVentaPerdida,
      consultarMargen: reportes.consultarMargen,
      consultarRotacion: reportes.consultarRotacion,
      exportarDatos: exportarDatos,
      gestionarUsuarios: gestionarUsuarios,
      generarReporteDiario: reportes.generarReporteDiario,
      registrarMovimientoCaja: cajaPropietario.registrarMovimientoCaja,
      registrarCierreCaja: cajaPropietario.registrarCierreCaja,
      anularVenta: anularVenta,
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
    required this.registrarConteo,
    required this.consultarExistencias,
    required this.registrarVenta,
    required this.registrarFiado,
    required this.registrarAbono,
    required this.consultarCliente,
    required this.generarAlertas,
    required this.consultarAlertas,
    required this.registrarVentaPerdida,
    required this.consultarMargen,
    required this.consultarRotacion,
    required this.exportarDatos,
    required this.gestionarUsuarios,
    required this.generarReporteDiario,
    required this.registrarMovimientoCaja,
    required this.registrarCierreCaja,
    required this.anularVenta,
  });

  final IniciarSesionCoordinator iniciarSesion;
  final GestionarProductoCoordinator gestionarProducto;
  final BuscarProductoCoordinator buscarProducto;
  final RegistrarEntradaMercanciaCoordinator registrarEntradaMercancia;
  final RegistrarPerdidaCoordinator registrarPerdida;
  final RegistrarConteoCoordinator registrarConteo;
  final ConsultarExistenciasCoordinator consultarExistencias;
  final RegistrarVentaCoordinator registrarVenta;
  final RegistrarFiadoCoordinator registrarFiado;
  final RegistrarAbonoCoordinator registrarAbono;
  final ConsultarClienteCoordinator consultarCliente;
  final GenerarAlertasDiariasCoordinator generarAlertas;
  final ConsultarAlertasCoordinator consultarAlertas;
  final RegistrarVentaPerdidaCoordinator registrarVentaPerdida;
  final ConsultarMargenCoordinator consultarMargen;
  final ConsultarRotacionCoordinator consultarRotacion;
  final ExportarDatosCoordinator exportarDatos;
  final GestionarUsuariosCoordinator gestionarUsuarios;
  final GenerarReporteDiarioCoordinator generarReporteDiario;
  final RegistrarMovimientoCajaCoordinator registrarMovimientoCaja;
  final RegistrarCierreCajaCoordinator registrarCierreCaja;
  final AnularVentaCoordinator anularVenta;

  @override
  State<GipApp> createState() => _GipAppState();
}

class _GipAppState extends State<GipApp> with WidgetsBindingObserver {
  late final IniciarSesionViewModel _sesion = IniciarSesionViewModel(
    widget.iniciarSesion,
  )..verificarSesionGuardada();
  late final GoRouter _router = crearRouter(_sesion);

  /// CUS-24 en cada arranque con usuario activo, sin bloquear (DI-25).
  late final DisparadorAlertasDiarias _alertasDiarias;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _alertasDiarias = DisparadorAlertasDiarias(_sesion, widget.generarAlertas);
  }

  /// Al volver del segundo plano, con internet, se comprueba que el
  /// propietario no haya desactivado al usuario mientras tanto (DI-44).
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) _sesion.revisarUsuarioActivo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alertasDiarias.dispose();
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
        Provider.value(value: widget.registrarConteo),
        Provider.value(value: widget.consultarExistencias),
        Provider.value(value: widget.registrarVenta),
        Provider.value(value: widget.registrarFiado),
        Provider.value(value: widget.registrarAbono),
        Provider.value(value: widget.consultarCliente),
        Provider.value(value: widget.consultarAlertas),
        Provider.value(value: widget.registrarVentaPerdida),
        Provider.value(value: widget.consultarMargen),
        Provider.value(value: widget.consultarRotacion),
        Provider.value(value: widget.exportarDatos),
        Provider.value(value: widget.gestionarUsuarios),
        Provider.value(value: widget.generarReporteDiario),
        Provider.value(value: widget.registrarMovimientoCaja),
        Provider.value(value: widget.registrarCierreCaja),
        Provider.value(value: widget.anularVenta),
      ],
      child: MaterialApp.router(
        title: 'GIP',
        theme: TemaGip.claro(),
        locale: idiomasGip.first,
        supportedLocales: idiomasGip,
        localizationsDelegates: delegadosIdiomaGip,
        routerConfig: _router,
      ),
    );
  }
}
