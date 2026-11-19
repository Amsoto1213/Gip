import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/composition_root/registrar_caja.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';
import 'package:gip/presentation/caja/caja_view.dart';
import 'package:gip/presentation/caja/caja_view_model.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

/// Prueba de punta a punta de CUS-11: la vista con el módulo armado como en
/// `main.dart` y una base drift en memoria.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');

  late BaseLocalDrift base;

  setUp(() => base = BaseLocalDrift(NativeDatabase.memory()));
  tearDown(() => base.close());

  Future<void> abrir(
    WidgetTester tester, {
    Size tamano = const Size(390, 844),
    Usuario? usuario,
  }) async {
    final coordinadores = registrarCoordinadoresCaja(
      registrarCaja(base).servicioCaja,
      ServicioAcceso(AutenticacionFalsa(), SesionLocalFalsa()),
    );
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: ChangeNotifierProvider(
          create: (_) => CajaViewModel(coordinadores.registrarMovimientoCaja, (
            usuario: usuario ?? Administrador('2222', 'Carmen', '1'),
            tienda: tienda,
          ))..cargar(),
          child: const CajaView(),
        ),
      ),
    );
  }

  Future<void> esperarBase(WidgetTester tester) async {
    // Las consultas de drift corren fuera del reloj falso de la prueba.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> escribir(WidgetTester tester, String campo, String texto) =>
      tester.enterText(find.byKey(Key('caja_$campo')), texto);

  Future<void> anotar(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('caja_anotar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('caja_anotar')));
    await esperarBase(tester);
  }

  Future<List> movimientosDeHoy(WidgetTester tester) async {
    final hoy = DateTime.now();
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    return (await tester.runAsync(
      () =>
          CajaRepositorioDrift(base)
              .listarMovimientos(tienda, dia, dia.add(const Duration(days: 2))),
    ))!;
  }

  testWidgets('anota un gasto del negocio y confirma el movimiento', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.text('Caja'), findsOneWidget);
    expect(find.text('Anotar movimiento'), findsOneWidget);

    await escribir(tester, 'valor', '12.000');
    await escribir(tester, 'descripcion', 'Hielo');
    await anotar(tester);

    expect(
      find.textContaining('Movimiento registrado: Hielo · − \$ 12.000'),
      findsOneWidget,
    );
    final guardados = await movimientosDeHoy(tester);
    expect(guardados, hasLength(1));
    final m = guardados.single;
    expect(m.getValor(), Decimal.parse('12000'));
    expect(m.getTipo(), TipoMovimientoCaja.egreso);
    expect(m.getClasificacion(), ClasificacionMovimiento.negocio);
    // El formulario queda limpio para el siguiente movimiento.
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('caja_valor')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('"Entra dinero" y "Personal" se guardan como se eligieron', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.text('Entra dinero'));
    await tester.tap(find.text('Personal'));
    await tester.pump();
    await escribir(tester, 'valor', '5.000');
    await escribir(tester, 'descripcion', 'Aporte');
    await anotar(tester);

    final m = (await movimientosDeHoy(tester)).single;
    expect(m.getTipo(), TipoMovimientoCaja.ingreso);
    expect(m.getClasificacion(), ClasificacionMovimiento.personal);
  });

  testWidgets('un valor cero muestra el mensaje del diagrama', (tester) async {
    await abrir(tester);

    await escribir(tester, 'valor', '0');
    await anotar(tester);

    expect(find.text('El valor debe ser mayor que cero'), findsOneWidget);
    expect(await movimientosDeHoy(tester), isEmpty);
  });

  testWidgets('el empleado no registra nada y ve el rechazo', (tester) async {
    await abrir(tester, usuario: Empleado('3333', 'Luis', '2'));

    await escribir(tester, 'valor', '12.000');
    await escribir(tester, 'descripcion', 'Hielo');
    await anotar(tester);

    expect(
      find.text('Solo el propietario de la tienda puede hacer esto'),
      findsOneWidget,
    );
    expect(await movimientosDeHoy(tester), isEmpty);
  });

  testWidgets('en escritorio titula "Caja de hoy" y explica las anulaciones', (
    tester,
  ) async {
    await abrir(tester, tamano: const Size(1280, 800));

    expect(find.text('Caja de hoy'), findsOneWidget);
    expect(
      find.text(
        'Las anulaciones de ventas se anotan solas; no se escriben aquí.',
      ),
      findsOneWidget,
    );
    expect(find.text('Anotar movimiento'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin desbordes en 360×640 y con áreas de 44 px (RNF-19)', (
    tester,
  ) async {
    await abrir(tester, tamano: const Size(360, 640));

    for (final texto in ['Sale dinero', 'Entra dinero', 'Del negocio']) {
      final caja = tester.getSize(
        find
            .ancestor(of: find.text(texto), matching: find.byType(InkWell))
            .first,
      );
      expect(caja.height, greaterThanOrEqualTo(44), reason: texto);
    }
    await tester.ensureVisible(find.byKey(const Key('caja_anotar')));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const Key('caja_anotar'))).height,
      greaterThanOrEqualTo(44),
    );
    expect(tester.takeException(), isNull);
  });

  /// Anota un movimiento de hoy antes de abrir la pantalla.
  Future<void> sembrar(
    WidgetTester tester,
    TipoMovimientoCaja tipo,
    ClasificacionMovimiento clase,
    String valor,
    String descripcion,
  ) => tester.runAsync(
    () =>
        registrarCoordinadoresCaja(
          registrarCaja(base).servicioCaja,
          ServicioAcceso(AutenticacionFalsa(), SesionLocalFalsa()),
        ).registrarMovimientoCaja.registrarMovimiento(
          tienda,
          tipo,
          clase,
          Decimal.parse(valor),
          descripcion,
          Administrador('2222', 'Carmen', '1'),
        ),
  );

  testWidgets('muestra lo que debe haber en caja y se actualiza al anotar', (
    tester,
  ) async {
    await abrir(tester);
    await esperarBase(tester);
    expect(find.text('Debe haber en caja'), findsOneWidget);
    expect(find.text('\$ 0'), findsOneWidget);
    expect(find.byKey(const Key('caja_cerrar')), findsOneWidget);

    await tester.tap(find.text('Entra dinero'));
    await tester.pump();
    await escribir(tester, 'valor', '100.000');
    await escribir(tester, 'descripcion', 'Base de apertura');
    await anotar(tester);
    await esperarBase(tester);

    expect(find.text('\$ 100.000'), findsWidgets);
  });

  testWidgets('abre con lo contado al cerrar el día anterior y lo dice', (
    tester,
  ) async {
    // La caja de ayer, cerrada con $ 315.000 contados.
    final ayer = DateTime.now().subtract(const Duration(days: 1));
    final dia = DateTime(ayer.year, ayer.month, ayer.day);
    final repositorio = CajaRepositorioDrift(base);
    await tester.runAsync(() async {
      final caja = Caja(
        ServicioCaja.idCaja(tienda, dia),
        dia,
        baseApertura: Decimal.zero,
      );
      await repositorio.crear(tienda, caja);
      caja.cerrar(Decimal.parse('315000'));
      await repositorio.cerrar(tienda, caja);
    });

    await abrir(tester, tamano: const Size(1280, 800));
    await esperarBase(tester);

    expect(find.text('Abrió con \$ 315.000'), findsOneWidget);
    expect(find.byKey(const Key('caja_saldo_esperado')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('caja_saldo_esperado'))).data,
      '\$ 315.000',
    );
  });

  testWidgets('en escritorio muestra las cifras y la tabla de hoy', (
    tester,
  ) async {
    await sembrar(
      tester,
      TipoMovimientoCaja.ingreso,
      ClasificacionMovimiento.negocio,
      '268000',
      'Venta',
    );
    await sembrar(
      tester,
      TipoMovimientoCaja.egreso,
      ClasificacionMovimiento.negocio,
      '12000',
      'Hielo',
    );
    await sembrar(
      tester,
      TipoMovimientoCaja.egreso,
      ClasificacionMovimiento.personal,
      '40000',
      'Retiro',
    );

    await abrir(tester, tamano: const Size(1280, 800));
    await esperarBase(tester);

    String texto(String clave) =>
        tester.widget<Text>(find.byKey(Key(clave))).data!;
    expect(texto('caja_saldo_esperado'), '\$ 216.000');
    expect(texto('caja_entro_hoy'), '\$ 268.000');
    expect(texto('caja_gastos'), '\$ 12.000');
    expect(texto('caja_personal'), '\$ 40.000');
    expect(find.text('1 movimiento'), findsOneWidget);
    expect(find.text('Movimientos de hoy'), findsOneWidget);
    expect(find.text('Hielo'), findsOneWidget);
    expect(find.text('− \$ 12.000'), findsOneWidget);
    expect(find.text('+ \$ 268.000'), findsOneWidget);
    expect(find.text('Personal'), findsWidgets);
    expect(find.byKey(const Key('caja_cerrar')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el movimiento recién anotado aparece primero en la lista', (
    tester,
  ) async {
    await sembrar(
      tester,
      TipoMovimientoCaja.egreso,
      ClasificacionMovimiento.negocio,
      '6000',
      'Bolsas',
    );
    await abrir(tester);
    await esperarBase(tester);
    expect(find.text('Hoy'), findsOneWidget);

    await escribir(tester, 'valor', '12.000');
    await escribir(tester, 'descripcion', 'Hielo');
    await anotar(tester);
    await esperarBase(tester);

    final hielo = tester.getTopLeft(find.text('Hielo').last);
    final bolsas = tester.getTopLeft(find.text('Bolsas'));
    expect(hielo.dy, lessThan(bolsas.dy));
  });

  testWidgets('sin movimientos dice que todavía no hay', (tester) async {
    await abrir(tester);
    await esperarBase(tester);

    expect(find.byKey(const Key('caja_sin_movimientos')), findsOneWidget);
  });

  testWidgets('el empleado no ve el saldo, las cifras ni la lista', (
    tester,
  ) async {
    await abrir(tester, usuario: Empleado('3333', 'Luis', '2'));
    await esperarBase(tester);

    expect(find.text('Debe haber en caja'), findsNothing);
    expect(find.byKey(const Key('caja_cerrar')), findsNothing);
    expect(find.byKey(const Key('caja_movimientos_hoy')), findsNothing);
    expect(find.text('Abrió con'), findsNothing);
  });
}
