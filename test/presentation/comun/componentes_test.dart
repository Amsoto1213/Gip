import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/presentation/comun/barra_busqueda.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/chip_estado.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/icono_paquete.dart';
import 'package:gip/presentation/comun/logo_gip.dart';
import 'package:gip/presentation/comun/opcion_con_icono.dart';
import 'package:gip/presentation/comun/resumen_movimiento.dart';
import 'package:gip/presentation/comun/seccion_numerada.dart';
import 'package:gip/presentation/comun/tarjeta_accion.dart';
import 'package:gip/presentation/comun/tarjeta_gip.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';

/// Monta [hijo] con el tema del GIP en una pantalla de [ancho] px.
Future<void> montar(
  WidgetTester tester,
  Widget hijo, {
  double ancho = 390,
}) async {
  tester.view.physicalSize = Size(ancho, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: TemaGip.claro(),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: hijo),
      ),
    ),
  );
}

/// Sombras de la primera caja decorada debajo de [de].
List<BoxShadow>? sombrasDe(WidgetTester tester, Finder de) {
  final cajas = tester.widgetList<Container>(
    find.descendant(of: de, matching: find.byType(Container)),
  );
  for (final caja in cajas) {
    final decoracion = caja.decoration;
    if (decoracion is BoxDecoration && decoracion.boxShadow != null) {
      return decoracion.boxShadow;
    }
  }
  return null;
}

void main() {
  group('TarjetaGip', () {
    testWidgets('usa la sombra tarjeta, o la elevada si se pide', (
      tester,
    ) async {
      await montar(tester, const TarjetaGip(child: Text('Hola')));
      expect(find.text('Hola'), findsOneWidget);
      expect(
        sombrasDe(tester, find.byType(TarjetaGip)),
        FormaGip.sombraTarjeta,
      );

      await montar(
        tester,
        const TarjetaGip(elevada: true, child: Text('Hola')),
      );
      expect(
        sombrasDe(tester, find.byType(TarjetaGip)),
        FormaGip.sombraElevada,
      );
    });
  });

  testWidgets('SeccionNumerada muestra número, título y etiqueta', (
    tester,
  ) async {
    await montar(
      tester,
      const SeccionNumerada(
        numero: 2,
        titulo: 'Motivo',
        etiqueta: 'Obligatorio',
        child: Text('Contenido'),
      ),
    );
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Motivo'), findsOneWidget);
    expect(find.text('Obligatorio'), findsOneWidget);
    expect(find.text('Contenido'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });

  group('BotonPrimario', () {
    testWidgets('se toca, mide al menos 56 px y tiene sombra', (tester) async {
      var tocado = 0;
      await montar(
        tester,
        BotonPrimario(
          texto: 'Entrar',
          icono: Icons.arrow_forward,
          iconoAlFinal: true,
          onPressed: () => tocado++,
        ),
      );
      await tester.tap(find.text('Entrar'));
      expect(tocado, 1);
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(56),
      );
      final caja = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(BotonPrimario),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (caja.decoration as BoxDecoration).boxShadow,
        FormaGip.sombraBotonPrimario,
      );
    });

    testWidgets('cargando: muestra el indicador y no se puede tocar', (
      tester,
    ) async {
      var tocado = 0;
      await montar(
        tester,
        BotonPrimario(
          texto: 'Guardar',
          cargando: true,
          onPressed: () => tocado++,
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Guardar'));
      expect(tocado, 0);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('sin onPressed queda deshabilitado y sin sombra', (
      tester,
    ) async {
      await montar(
        tester,
        const BotonPrimario(texto: 'Registrar', onPressed: null),
      );
      final caja = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(BotonPrimario),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((caja.decoration as BoxDecoration).boxShadow, isNull);
    });
  });

  testWidgets('BotonSecundario se toca y tiene área táctil de 44 px', (
    tester,
  ) async {
    var tocado = 0;
    await montar(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: BotonSecundario(
          texto: 'Cambiar producto',
          icono: Icons.swap_horiz,
          onPressed: () => tocado++,
        ),
      ),
    );
    await tester.tap(find.text('Cambiar producto'));
    expect(tocado, 1);
    expect(
      tester.getSize(find.byType(OutlinedButton)).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('BotonIconoPrimario: cuadrado de 48 px con su tooltip', (
    tester,
  ) async {
    var tocado = 0;
    await montar(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: BotonIconoPrimario(
          icono: Icons.add,
          tooltip: 'Producto nuevo',
          onPressed: () => tocado++,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Producto nuevo'));
    expect(tocado, 1);
    expect(tester.getSize(find.byType(IconButton)), const Size.square(48));
  });

  group('CampoGip', () {
    testWidgets('muestra la etiqueta, escribe y marca el foco con el halo', (
      tester,
    ) async {
      final controlador = TextEditingController();
      addTearDown(controlador.dispose);
      await montar(
        tester,
        CampoGip(
          etiqueta: 'Correo',
          controlador: controlador,
          campoKey: const Key('correo'),
          icono: Icons.mail_outline,
          pista: 'nombre@tienda.com',
        ),
      );
      expect(find.text('Correo'), findsOneWidget);
      expect(find.text('nombre@tienda.com'), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);

      List<BoxShadow>? halo() =>
          (tester
                      .widget<AnimatedContainer>(
                        find.descendant(
                          of: find.byType(CampoGip),
                          matching: find.byType(AnimatedContainer),
                        ),
                      )
                      .decoration
                  as BoxDecoration?)
              ?.boxShadow;
      expect(halo(), isNull);

      await tester.enterText(find.byKey(const Key('correo')), 'a@b.co');
      await tester.pumpAndSettle();
      expect(controlador.text, 'a@b.co');
      expect(halo(), FormaGip.haloFoco);
      expect(
        tester.getSize(find.byKey(const Key('correo'))).height,
        greaterThanOrEqualTo(52),
      );
    });

    testWidgets('contraseña: el ojo muestra y oculta el texto', (tester) async {
      final controlador = TextEditingController(text: 'secreta');
      addTearDown(controlador.dispose);
      await montar(
        tester,
        CampoGip(
          etiqueta: 'Contraseña',
          controlador: controlador,
          campoKey: const Key('clave'),
          contrasena: true,
        ),
      );
      bool oculta() =>
          tester.widget<TextField>(find.byKey(const Key('clave'))).obscureText;
      expect(oculta(), isTrue);
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(oculta(), isFalse);
      await tester.tap(find.byTooltip('Ocultar contraseña'));
      await tester.pump();
      expect(oculta(), isTrue);
    });
  });

  group('BarraBusqueda', () {
    testWidgets('como botón: llama a onTap y no muestra el lector', (
      tester,
    ) async {
      var tocado = 0;
      await montar(
        tester,
        BarraBusqueda(pista: 'Buscar en el surtido…', onTap: () => tocado++),
      );
      await tester.tap(find.text('Buscar en el surtido…'));
      expect(tocado, 1);
      expect(find.byTooltip('Leer código con el lector'), findsNothing);
      expect(tester.getSize(find.byType(BarraBusqueda)).height, 52);
    });

    testWidgets('en la web mide 58 px y muestra el lector si se pide', (
      tester,
    ) async {
      var leido = 0;
      await montar(
        tester,
        ancho: 1280,
        BarraBusqueda(
          pista: 'Buscar',
          onTap: () {},
          onLeerCodigo: () => leido++,
        ),
      );
      expect(tester.getSize(find.byType(AnimatedContainer)).height, 58);
      await tester.tap(find.byTooltip('Leer código con el lector'));
      expect(leido, 1);
    });

    testWidgets('como campo: se escribe ahí mismo', (tester) async {
      final controlador = TextEditingController();
      addTearDown(controlador.dispose);
      final escrito = <String>[];
      await montar(
        tester,
        BarraBusqueda(
          pista: 'Nombre del producto',
          controlador: controlador,
          campoKey: const Key('buscar'),
          onChanged: escrito.add,
        ),
      );
      await tester.enterText(find.byKey(const Key('buscar')), 'arroz');
      expect(escrito, ['arroz']);
    });
  });

  group('TarjetaAccion', () {
    testWidgets('horizontal: título, descripción y toque', (tester) async {
      var tocado = 0;
      await montar(
        tester,
        TarjetaAccion(
          icono: Icons.south,
          titulo: 'Registrar entrada',
          descripcion: 'Llegó mercancía del proveedor',
          onTap: () => tocado++,
        ),
      );
      expect(find.text('Llegó mercancía del proveedor'), findsOneWidget);
      await tester.tap(find.text('Registrar entrada'));
      expect(tocado, 1);
    });

    testWidgets('vertical: solo el título a la vista, 92 px de alto', (
      tester,
    ) async {
      await montar(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 110,
            child: TarjetaAccion(
              icono: Icons.south,
              titulo: 'Entrada',
              descripcion: 'Llegó mercancía del proveedor',
              vertical: true,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Entrada'), findsOneWidget);
      expect(find.text('Llegó mercancía del proveedor'), findsNothing);
      expect(tester.getSize(find.byType(TarjetaAccion)).height, 92);
      expect(
        find.bySemanticsLabel('Entrada. Llegó mercancía del proveedor'),
        findsOneWidget,
      );
    });
  });

  testWidgets('ChipEstado: Poco en alerta y Agotado en error', (tester) async {
    await montar(
      tester,
      const Row(
        children: [
          ChipEstado(EstadoExistencia.poco),
          ChipEstado(EstadoExistencia.agotado),
        ],
      ),
    );
    expect(
      tester.widget<Text>(find.text('Poco')).style?.color,
      ColoresGip.alertaTexto,
    );
    expect(
      tester.widget<Text>(find.text('Agotado')).style?.color,
      ColoresGip.error,
    );
  });

  testWidgets('OpcionConIcono: elegida con verificación y borde primario', (
    tester,
  ) async {
    var tocado = 0;
    Widget opcion(bool elegida) => OpcionConIcono(
      icono: Icons.event_busy,
      titulo: 'Vencido',
      descripcion: 'Pasó la fecha de vencimiento',
      elegida: elegida,
      onTap: () => tocado++,
    );
    await montar(tester, opcion(false));
    expect(find.byIcon(Icons.check_circle), findsNothing);
    await tester.tap(find.text('Vencido'));
    expect(tocado, 1);

    await montar(tester, opcion(true));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(OpcionConIcono),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, ColoresGip.primarioSuave);
    expect(
      (material.shape! as RoundedRectangleBorder).side.color,
      ColoresGip.primario,
    );
  });

  group('ResumenMovimiento', () {
    testWidgets('muestra antes, después, la barra y las filas', (tester) async {
      await montar(
        tester,
        ancho: 1280,
        SingleChildScrollView(
          child: ResumenMovimiento(
            antes: '14',
            despues: '12',
            fraccionQueda: 12 / 14,
            detalles: const [
              FilaDetalle('Producto', 'Leche bolsa 1 L'),
              FilaDetalle('Salen', '− 2 und', resta: true),
            ],
            pie: [BotonPrimario(texto: 'Registrar pérdida', onPressed: () {})],
          ),
        ),
      );
      expect(find.text('Hay ahora'), findsOneWidget);
      expect(find.text('Quedará en'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.byKey(const Key('resumen_barra')), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('− 2 und')).style?.color,
        ColoresGip.error,
      );
      expect(find.text('Registrar pérdida'), findsOneWidget);
    });

    testWidgets('sin fracción no hay barra (entrada)', (tester) async {
      await montar(tester, const ResumenMovimiento(antes: '8', despues: '32'));
      expect(find.byKey(const Key('resumen_barra')), findsNothing);
    });
  });

  testWidgets('LogoGip: ícono de paquete o la sigla', (tester) async {
    await montar(tester, const LogoGip(tamano: 104, sobreVerde: true));
    expect(find.byType(IconoPaquete), findsOneWidget);
    expect(tester.getSize(find.byType(LogoGip)), const Size.square(104));

    await montar(tester, const LogoGip.sigla());
    expect(find.text('GIP'), findsOneWidget);
    expect(find.byType(IconoPaquete), findsNothing);
  });

  group('EncabezadoPantalla', () {
    testWidgets('web: miga que vuelve y título de 34 px', (tester) async {
      var volvio = 0;
      await montar(
        tester,
        ancho: 1280,
        EncabezadoPantalla(
          titulo: 'Registrar pérdida o devolución',
          miga: 'Pérdida o devolución',
          seccion: 'Surtido',
          contexto: 'Saque del surtido lo que se venció.',
          onVolver: () => volvio++,
        ),
      );
      expect(find.text('Pérdida o devolución'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.text('Registrar pérdida o devolución'))
            .style
            ?.fontSize,
        34,
      );
      await tester.tap(find.byTooltip('Volver a Surtido'));
      expect(volvio, 1);
    });

    testWidgets('móvil: botón Volver; sin volver, título de 30 px y acción', (
      tester,
    ) async {
      var volvio = 0;
      await montar(
        tester,
        EncabezadoPantalla(
          titulo: 'Pérdida o devolución',
          seccion: 'Surtido',
          onVolver: () => volvio++,
        ),
      );
      expect(find.text('SURTIDO'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      expect(volvio, 1);

      await montar(
        tester,
        const EncabezadoPantalla(
          titulo: 'Surtido',
          contexto: 'Entradas, pérdidas y productos de la tienda',
          accion: Icon(Icons.add),
        ),
      );
      expect(tester.widget<Text>(find.text('Surtido')).style?.fontSize, 30);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
