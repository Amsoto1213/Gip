import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/composition_root/registrar_caja.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/gestion_caja/caja_repositorio_drift.dart';
import 'package:gip/presentation/caja/cierre_caja_view.dart';
import 'package:gip/presentation/caja/cierre_caja_view_model.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

/// Prueba de punta a punta de CUS-14: la vista con el módulo armado como en
/// `main.dart` y una base drift en memoria.
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  Decimal d(String v) => Decimal.parse(v);

  late BaseLocalDrift base;
  late CoordinadoresCaja coordinadores;

  setUp(() {
    base = BaseLocalDrift(NativeDatabase.memory());
    final servicio = registrarCaja(base).servicioCaja;
    coordinadores = registrarCoordinadoresCaja(
      servicio,
      ServicioAcceso(AutenticacionFalsa(), SesionLocalFalsa()),
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

  /// Anota un ingreso del negocio de [valor] antes de abrir la pantalla.
  Future<void> conSaldo(WidgetTester tester, String valor) async {
    await tester.runAsync(
      () => coordinadores.registrarMovimientoCaja.registrarMovimiento(
        tienda,
        TipoMovimientoCaja.ingreso,
        ClasificacionMovimiento.negocio,
        d(valor),
        'Venta',
        Administrador('2222', 'Carmen', '1'),
      ),
    );
  }

  Future<void> abrir(
    WidgetTester tester, {
    Size tamano = const Size(390, 844),
    Usuario? usuario,
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: ChangeNotifierProvider(
          create: (_) =>
              CierreCajaViewModel(coordinadores.registrarCierreCaja, (
                usuario: usuario ?? Administrador('2222', 'Carmen', '1'),
                tienda: tienda,
              ))..cargar(),
          child: const CierreCajaView(),
        ),
      ),
    );
    await esperarBase(tester);
  }

  Future<void> contar(WidgetTester tester, String texto) async {
    await tester.enterText(find.byKey(const Key('cierre_efectivo')), texto);
    await tester.pump();
  }

  Future<void> cerrar(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('cierre_cerrar')));
    await esperarBase(tester);
  }

  testWidgets('muestra lo que debe haber, la vista previa y cierra con '
      'faltante', (tester) async {
    await conSaldo(tester, '318500');
    await abrir(tester);

    expect(find.text('Cerrar caja'), findsWidgets);
    expect(find.byKey(const Key('cierre_saldo_esperado')), findsOneWidget);
    expect(find.text(r'$ 318.500'), findsOneWidget);
    expect(find.byKey(const Key('cierre_vista_previa')), findsNothing);

    await contar(tester, '315.000');
    expect(find.text('Faltan'), findsOneWidget);
    expect(find.text(r'$ 3.500'), findsOneWidget);
    expect(find.text('Cerrar caja con faltante'), findsOneWidget);

    await cerrar(tester);

    expect(find.byKey(const Key('cierre_resultado')), findsOneWidget);
    expect(find.text('Faltan'), findsOneWidget);
    expect(find.byKey(const Key('cierre_cerrada')), findsOneWidget);
    expect(find.byKey(const Key('cierre_volver_caja')), findsOneWidget);

    final caja = await tester.runAsync(
      () => CajaRepositorioDrift(base).buscarPorFecha(
        tienda,
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      ),
    );
    expect(caja!.isCerrada(), isTrue);
    expect(caja.getEfectivoContado(), d('315000'));
    expect(caja.getDiferencia(), d('-3500'));
  });

  testWidgets('con más efectivo dice "con sobrante" y con el mismo, cuadra', (
    tester,
  ) async {
    await conSaldo(tester, '1000');
    await abrir(tester);

    await contar(tester, '1.500');
    expect(find.text('Sobran'), findsOneWidget);
    expect(find.text('Cerrar caja con sobrante'), findsOneWidget);

    await contar(tester, '1.000');
    expect(find.text('La caja cuadra'), findsOneWidget);
    expect(find.byKey(const Key('diferencia_valor')), findsNothing);
    expect(find.text('Cerrar caja'), findsWidgets);
  });

  testWidgets('"Volver a contar" borra el efectivo y la vista previa', (
    tester,
  ) async {
    await conSaldo(tester, '1000');
    await abrir(tester);
    await contar(tester, '900');
    expect(find.byKey(const Key('cierre_vista_previa')), findsOneWidget);

    await tester.tap(find.byKey(const Key('cierre_volver_a_contar')));
    await tester.pump();

    expect(find.byKey(const Key('cierre_vista_previa')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('cierre_efectivo')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('sin efectivo escrito, cerrar está desactivado', (tester) async {
    await abrir(tester);

    final boton = find.descendant(
      of: find.byKey(const Key('cierre_cerrar')),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(boton).onPressed, isNull);
  });

  testWidgets('un segundo cierre muestra "La caja de hoy ya está cerrada"', (
    tester,
  ) async {
    await abrir(tester);
    await tester.runAsync(
      () => coordinadores.registrarCierreCaja.cerrarCaja(
        tienda,
        Decimal.zero,
        Administrador('2222', 'Carmen', '1'),
      ),
    );

    await contar(tester, '0');
    await cerrar(tester);

    expect(find.text('La caja de hoy ya está cerrada'), findsOneWidget);
    expect(find.byKey(const Key('cierre_resultado')), findsNothing);
  });

  testWidgets('el empleado ve el rechazo y no puede cerrar', (tester) async {
    await abrir(tester, usuario: Empleado('3333', 'Luis', '2'));

    expect(
      find.text('Solo el propietario de la tienda puede hacer esto'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('cierre_efectivo')), findsNothing);
  });

  testWidgets('en escritorio: dos tarjetas y título "Cierre de caja"', (
    tester,
  ) async {
    await conSaldo(tester, '1000');
    await abrir(tester, tamano: const Size(1280, 800));

    expect(find.text('Cierre de caja'), findsWidgets);
    expect(find.text('Lo que debe haber'), findsOneWidget);
    expect(find.text('Lo que usted contó'), findsOneWidget);
    final izquierda = tester.getRect(
      find.byKey(const Key('cierre_tarjeta_debe_haber')),
    );
    final derecha = tester.getRect(
      find.byKey(const Key('cierre_tarjeta_contado')),
    );
    expect(derecha.left, greaterThan(izquierda.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin desbordes en 360×640 y con áreas de 44 px (RNF-19)', (
    tester,
  ) async {
    await conSaldo(tester, '318500');
    await abrir(tester, tamano: const Size(360, 640));
    await contar(tester, '315.000');

    for (final clave in ['cierre_cerrar', 'cierre_volver_a_contar']) {
      expect(
        tester.getSize(find.byKey(Key(clave))).height,
        greaterThanOrEqualTo(44),
        reason: clave,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
