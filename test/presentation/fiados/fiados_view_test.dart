import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/gestion_inventario/unidad_medida.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/entidades/pagos/linea_venta.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/business/workflow/info_tienda/iniciar_sesion_coordinator.dart';
import 'package:gip/composition_root/registrar_caja.dart';
import 'package:gip/composition_root/registrar_inventario.dart';
import 'package:gip/composition_root/registrar_pagos.dart';
import 'package:gip/data/helpers/unidad_trabajo_drift.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/main.dart';
import 'package:gip/presentation/comun/barra_inferior.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/menu_lateral.dart';
import 'package:mocktail/mocktail.dart';

import '../negocio/alertas_falsos.dart';
import '../negocio/margen_falsos.dart';
import '../negocio/rotacion_falsos.dart';
import '../negocio/reporte_falsos.dart';
import '../surtido/existencias_falsos.dart';
import '../caja/caja_falsos.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

/// Fiados de punta a punta (CUS-19 mínimo y CUS-08): la app con los módulos
/// armados como en `main.dart` sobre una base drift en memoria; solo el inicio
/// de sesión es falso. María Pérez debe dos fiados, de $ 2.800 y $ 5.600.
void main() {
  final tienda = Tienda('1111', 'T001', 'Granero El Porvenir', 'Arjona');
  final UsuarioActivo carmen = (
    usuario: Administrador('2222', 'Carmen', '1000000001'),
    tienda: tienda,
  );
  Decimal d(String v) => Decimal.parse(v);

  late BaseLocalDrift base;
  late CoordinadoresInventario inventario;
  late CoordinadoresPagos pagos;

  setUp(() {
    base = BaseLocalDrift(NativeDatabase.memory());
    final unidad = UnidadTrabajoDrift(base);
    inventario = registrarInventario(base, unidad);
    pagos = registrarPagos(
      base,
      unidad,
      inventario.servicioInventario,
      registrarCaja(base).servicioCaja,
    );
  });
  tearDown(() => base.close());

  Future<void> esperarBase(WidgetTester tester) async {
    // Las consultas de drift corren fuera del reloj falso de la prueba.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  /// María Pérez, con dos fiados, y Luz, que está al día.
  Future<void> sembrar(WidgetTester tester) async {
    await tester.runAsync(() async {
      final arroz = await inventario.gestionarProducto.crearProducto(
        tienda,
        'ARR',
        'Arroz 500 g',
        UnidadMedida.unidad,
        d('1000'),
        d('2800'),
      );
      await inventario.registrarEntradaMercancia.registrarEntrada(
        tienda,
        arroz,
        d('10'),
        d('1000'),
        null,
      );
      final maria = await pagos.registrarFiado.registrarCliente(
        tienda,
        'María Pérez',
        '300 412 4521',
      );
      await pagos.registrarFiado.registrarCliente(tienda, 'Luz Díaz', '');
      for (final cantidad in ['1', '2']) {
        final lineas = <LineaVenta>[];
        await pagos.registrarVenta.agregarProducto(
          tienda,
          lineas,
          arroz,
          d(cantidad),
        );
        final total = pagos.registrarVenta.obtenerTotal(lineas);
        await pagos.registrarVenta.confirmarVenta(tienda, lineas, [
          pagos.registrarFiado.prepararFiado(maria, total),
        ]);
      }
    });
  }

  Future<void> abrir(WidgetTester tester, Size tamano) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final autenticacion = AutenticacionFalsa();
    final sesionLocal = SesionLocalFalsa();
    when(() => autenticacion.haySesionGuardada()).thenReturn(true);
    when(() => sesionLocal.leer()).thenAnswer((_) async => carmen);
    await tester.pumpWidget(
      GipApp(
        iniciarSesion: IniciarSesionCoordinator(
          ServicioAcceso(autenticacion, sesionLocal),
        ),
        gestionarProducto: inventario.gestionarProducto,
        buscarProducto: inventario.buscarProducto,
        registrarEntradaMercancia: inventario.registrarEntradaMercancia,
        registrarPerdida: inventario.registrarPerdida,
        registrarConteo: inventario.registrarConteo,
        consultarExistencias: ConsultarExistenciasFalso(),
        registrarVenta: pagos.registrarVenta,
        registrarFiado: pagos.registrarFiado,
        registrarAbono: pagos.registrarAbono,
        consultarCliente: pagos.consultarCliente,
        generarAlertas: GenerarAlertasFalso(),
        consultarAlertas: ConsultarAlertasFalso(),
        registrarVentaPerdida: RegistrarVentaPerdidaFalso(),
        consultarMargen: ConsultarMargenFalso(),
        consultarRotacion: ConsultarRotacionFalso(),
        generarReporteDiario: GenerarReporteDiarioFalso(),
        registrarMovimientoCaja: RegistrarMovimientoCajaFalso(),
        registrarCierreCaja: RegistrarCierreCajaFalso(),
        anularVenta: AnularVentaFalso(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, Finder buscador) async {
    await tester.ensureVisible(buscador);
    await tester.pumpAndSettle();
    await tester.tap(buscador);
    await tester.pumpAndSettle();
  }

  Future<void> irAFiados(WidgetTester tester, Type navegacion) async {
    await tocar(
      tester,
      find.descendant(
        of: find.byType(navegacion),
        matching: find.text('Fiados'),
      ),
    );
    await esperarBase(tester);
  }

  Future<List<Map<String, Object?>>> filas(
    WidgetTester tester,
    String sql,
  ) async => (await tester.runAsync(() async {
    final r = await base.customSelect(sql).get();
    return r.map((f) => f.data).toList();
  }))!;

  testWidgets('móvil: lista, cliente y abono en efectivo a un fiado '
      '(CUS-19 y CUS-08)', (tester) async {
    await sembrar(tester);
    await abrir(tester, const Size(360, 640));
    await irAFiados(tester, BarraInferior);

    expect(find.text('Le deben \$ 8.400 · 1 cliente'), findsOneWidget);
    expect(find.text('María Pérez'), findsOneWidget);
    expect(find.text('2 fiados · último ${_hoyCorto()}'), findsOneWidget);
    expect(find.text('Luz Díaz'), findsNothing); // "Deben" la oculta

    await tocar(tester, find.byKey(const Key('fiados_filtro_1')));
    expect(find.text('Luz Díaz'), findsOneWidget);
    expect(find.text('Al día'), findsOneWidget);
    await tocar(tester, find.byKey(const Key('fiados_filtro_0')));

    await tocar(tester, find.text('María Pérez'));
    expect(
      tester.widget<Text>(find.byKey(const Key('cliente_saldo_total'))).data,
      '\$ 8.400',
    );
    expect(find.text('Tel. 300 412 4521'), findsOneWidget);
    expect(find.text('Fió \$ 2.800 · sin abonos'), findsOneWidget);

    await tocar(tester, find.byKey(const Key('cliente_abonar')));
    expect(find.text('¿A cuál fiado abona?'), findsOneWidget);

    // Sin elegir fiado no deja abonar y lo dice.
    await tocar(tester, find.byKey(const Key('abono_registrar')));
    expect(find.text('Elija a cuál fiado abona'), findsOneWidget);

    await tocar(tester, find.text('\$ 2.800').last);
    expect(find.text('Elija a cuál fiado abona'), findsNothing);
    expect(
      find.text('Con este abono, el fiado del ', findRichText: true),
      findsNothing,
    );
    await tester.enterText(find.byKey(const Key('abono_monto')), '9.999');
    await tester.pumpAndSettle();
    expect(
      find.text(
        'El abono debe ser mayor que cero y no puede superar el saldo '
        'pendiente',
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('abono_monto')), '1.000');
    await tester.pumpAndSettle();
    expect(find.text('Registrar abono de \$ 1.000'), findsOneWidget);
    await tocar(tester, find.byKey(const Key('abono_registrar')));
    await esperarBase(tester);

    expect(
      find.text('Abono registrado. Nuevo saldo: \$ 1.800'),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('cliente_saldo_total'))).data,
      '\$ 7.400',
    );
    final abonos = await filas(tester, 'SELECT monto, medio FROM abonos');
    expect(abonos, hasLength(1));
    expect(abonos.single['medio'], 'EFECTIVO');
    final caja = await filas(
      tester,
      "SELECT valor FROM movimientos_caja WHERE descripcion = 'Abono'",
    );
    expect(caja.single['valor'], '1000');
    expect(tester.takeException(), isNull);
  });

  testWidgets('web: lista y cliente en una página; abono por Nequi que '
      'salda el fiado', (tester) async {
    await sembrar(tester);
    await abrir(tester, const Size(1280, 800));
    await irAFiados(tester, MenuLateral);

    expect(find.text('Le deben \$ 8.400 · 1 cliente'), findsOneWidget);
    expect(
      find.text('Elija un cliente para ver sus fiados y registrar un abono.'),
      findsOneWidget,
    );

    await tocar(tester, find.text('María Pérez'));
    expect(find.text('Registrar abono'), findsWidgets);
    expect(
      tester.widget<Text>(find.byKey(const Key('cliente_saldo_total'))).data,
      '\$ 8.400',
    );

    await tocar(tester, find.text('Fió \$ 2.800 · sin abonos'));
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('abono_monto')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      '2.800',
    );
    expect(find.byKey(const Key('abono_saldado')), findsOneWidget);

    await tocar(
      tester,
      find.descendant(
        of: find.byKey(const Key('abono_medio')),
        matching: find.text('Nequi'),
      ),
    );
    await tester.enterText(find.byKey(const Key('abono_referencia')), 'N-77');
    await tocar(tester, find.byKey(const Key('abono_registrar')));
    await esperarBase(tester);

    expect(find.text('Abono registrado. Nuevo saldo: \$ 0'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('cliente_saldo_total'))).data,
      '\$ 5.600',
    );
    final abonos = await filas(tester, 'SELECT medio, referencia FROM abonos');
    expect(abonos.single, {'medio': 'NEQUI', 'referencia': 'N-77'});
    expect(await filas(tester, 'SELECT 1 FROM movimientos_caja'), isEmpty);
    final fiados = await filas(
      tester,
      "SELECT estado FROM fiados WHERE estado = 'SALDADO'",
    );
    expect(fiados, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ancho intermedio (800 px): una columna, y el cliente y el '
      'abono abren como pantallas sin desbordes', (tester) async {
    await sembrar(tester);
    await abrir(tester, const Size(800, 800));
    await irAFiados(tester, BarraInferior);

    expect(
      find.text('Elija un cliente para ver sus fiados y registrar un abono.'),
      findsNothing,
    );
    await tocar(tester, find.text('María Pérez'));
    expect(find.byKey(const Key('cliente_abonar')), findsOneWidget);
    await tocar(tester, find.byKey(const Key('cliente_abonar')));
    expect(find.text('¿A cuál fiado abona?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('si el abono no se guarda: error en rojo y el cliente se '
      'vuelve a leer de la base (DI-27)', (tester) async {
    await sembrar(tester);
    await abrir(tester, const Size(1280, 800));
    await irAFiados(tester, MenuLateral);
    await tocar(tester, find.text('María Pérez'));
    await tocar(tester, find.text('Fió \$ 2.800 · sin abonos'));
    // Hace fallar el guardado del abono, como un error del disco.
    await tester.runAsync(
      () => base.customStatement(
        'CREATE TRIGGER abonos_falla BEFORE INSERT ON abonos BEGIN '
        "SELECT RAISE(ABORT, 'falla del disco'); END",
      ),
    );

    await tocar(tester, find.byKey(const Key('abono_registrar')));
    await esperarBase(tester);

    expect(
      find.text('No se pudo registrar el abono. Intente de nuevo'),
      findsOneWidget,
    );
    // El saldo que se ve es el de la base, no el rebajado en memoria.
    expect(
      tester.widget<Text>(find.byKey(const Key('cliente_saldo_total'))).data,
      '\$ 8.400',
    );
    expect(find.text('Fió \$ 2.800 · sin abonos'), findsOneWidget);
    expect(
      tester
          .widget<BotonPrimario>(find.byKey(const Key('abono_registrar')))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  Future<Map<String, Object?>> filaCliente(
    WidgetTester tester,
    String id,
  ) async =>
      (await filas(tester, "SELECT * FROM clientes WHERE id = '$id'")).single;

  Future<String> idDe(WidgetTester tester, String nombre) async =>
      (await filas(
            tester,
            "SELECT id FROM clientes WHERE nombre = '$nombre'",
          )).single['id']!
          as String;

  testWidgets('móvil: Eliminar datos del cliente al día. Cancelar no hace '
      'nada; confirmar lo anonimiza y vuelve a la lista (CUS-21)', (
    tester,
  ) async {
    await sembrar(tester);
    await abrir(tester, const Size(360, 640));
    await irAFiados(tester, BarraInferior);
    await tocar(tester, find.byKey(const Key('fiados_filtro_1')));
    await tocar(tester, find.text('Luz Díaz'));
    final id = await idDe(tester, 'Luz Díaz');

    // Cancelar: el diálogo se cierra y no pasa nada.
    await tocar(tester, find.byKey(const Key('cliente_eliminar')));
    expect(
      find.text('¿Confirma que desea eliminar los datos del cliente?'),
      findsOneWidget,
    );
    await tocar(tester, find.byKey(const Key('confirmacion_cancelar')));
    expect(find.byKey(const Key('dialogo_confirmacion')), findsNothing);
    expect(find.byKey(const Key('cliente_eliminar')), findsOneWidget);
    expect((await filaCliente(tester, id))['nombre'], 'Luz Díaz');
    expect((await filaCliente(tester, id))['eliminado_en'], isNull);

    // Confirmar.
    await tocar(tester, find.byKey(const Key('cliente_eliminar')));
    await tocar(tester, find.byKey(const Key('confirmacion_confirmar')));
    await esperarBase(tester);

    expect(find.text('Datos del cliente eliminados'), findsOneWidget);
    expect(find.byKey(const Key('cliente_eliminar')), findsNothing);
    expect(find.text('María Pérez'), findsOneWidget); // de vuelta en la lista
    expect(find.text('Luz Díaz'), findsNothing);
    final fila = await filaCliente(tester, id);
    expect(fila['nombre'], 'Cliente eliminado');
    expect(fila['telefono'], '');
    expect(fila['nombre_normalizado'], '');
    expect(fila['eliminado_en'], isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('móvil: cliente que aún debe: "No se pueden eliminar los '
      'datos: el cliente aún debe" y no se elimina (CUS-21)', (tester) async {
    await sembrar(tester);
    await abrir(tester, const Size(360, 640));
    await irAFiados(tester, BarraInferior);
    await tocar(tester, find.text('María Pérez'));
    final id = await idDe(tester, 'María Pérez');

    // Con dos fiados el botón queda debajo de la pantalla: hay que bajar.
    await tester.scrollUntilVisible(
      find.byKey(const Key('cliente_eliminar')),
      200,
    );
    await tocar(tester, find.byKey(const Key('cliente_eliminar')));
    await tocar(tester, find.byKey(const Key('confirmacion_confirmar')));
    await esperarBase(tester);

    // En el aviso flotante y en la tarjeta de arriba.
    expect(
      find.text('No se pueden eliminar los datos: el cliente aún debe'),
      findsWidgets,
    );
    expect(find.text('Datos del cliente eliminados'), findsNothing);
    expect(find.byKey(const Key('cliente_aviso')), findsOneWidget);
    final fila = await filaCliente(tester, id);
    expect(fila['nombre'], 'María Pérez');
    expect(fila['eliminado_en'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('web: eliminar los datos de un cliente al día deja la lista '
      'sin él y sin cliente elegido (CUS-21)', (tester) async {
    await sembrar(tester);
    await abrir(tester, const Size(1280, 800));
    await irAFiados(tester, MenuLateral);
    await tocar(tester, find.byKey(const Key('fiados_filtro_1')));
    await tocar(tester, find.text('Luz Díaz'));

    await tocar(tester, find.byKey(const Key('cliente_eliminar')));
    await tocar(tester, find.byKey(const Key('confirmacion_confirmar')));
    await esperarBase(tester);

    expect(find.text('Datos del cliente eliminados'), findsOneWidget);
    expect(find.text('Luz Díaz'), findsNothing);
    expect(find.byKey(const Key('fiados_elegir')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// "9 nov." de hoy, como lo muestra la lista.
String _hoyCorto() {
  const meses = [
    'ene.',
    'feb.',
    'mar.',
    'abr.',
    'may.',
    'jun.',
    'jul.',
    'ago.',
    'sep.',
    'oct.',
    'nov.',
    'dic.',
  ];
  final ahora = DateTime.now();
  return '${ahora.day} ${meses[ahora.month - 1]}';
}
