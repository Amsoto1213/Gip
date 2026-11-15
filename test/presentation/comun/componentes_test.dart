import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/presentation/comun/barra_busqueda.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/campo_gip.dart';
import 'package:gip/presentation/comun/chip_estado.dart';
import 'package:gip/presentation/comun/dialogo_confirmacion.dart';
import 'package:gip/presentation/comun/encabezado_pantalla.dart';
import 'package:gip/presentation/comun/icono_paquete.dart';
import 'package:gip/presentation/comun/logo_gip.dart';
import 'package:gip/presentation/comun/nota_info.dart';
import 'package:gip/presentation/comun/opcion_con_icono.dart';
import 'package:gip/presentation/comun/opcion_radio.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/resumen_movimiento.dart';
import 'package:gip/presentation/comun/seccion_numerada.dart';
import 'package:gip/presentation/comun/selector_filtro.dart';
import 'package:gip/presentation/comun/tarjeta_accion.dart';
import 'package:gip/presentation/comun/tarjeta_aviso.dart';
import 'package:gip/presentation/comun/tarjeta_cifra.dart';
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

    testWidgets('con valor: texto a la izquierda y monto a la derecha', (
      tester,
    ) async {
      await montar(
        tester,
        BotonPrimario(texto: 'Cobrar', valor: r'$ 5.600', onPressed: () {}),
      );
      expect(
        tester.getCenter(find.text(r'$ 5.600')).dx,
        greaterThan(tester.getCenter(find.text('Cobrar')).dx),
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(r'$ 5.600')).style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
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

  testWidgets('BotonIconoSecundario: cuadrado de 48 px, se desactiva', (
    tester,
  ) async {
    var tocado = 0;
    await montar(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: BotonIconoSecundario(
          icono: Icons.chevron_left,
          tooltip: 'Día anterior',
          onPressed: () => tocado++,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Día anterior'));
    expect(tocado, 1);
    expect(tester.getSize(find.byType(IconButton)), const Size.square(48));

    await montar(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: BotonIconoSecundario(
          icono: Icons.chevron_right,
          tooltip: 'Día siguiente',
          onPressed: null,
        ),
      ),
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
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

    testWidgets('muestra el error debajo del campo', (tester) async {
      final controlador = TextEditingController();
      addTearDown(controlador.dispose);
      await montar(
        tester,
        CampoGip(
          etiqueta: 'Efectivo recibido',
          controlador: controlador,
          error: 'El monto recibido no alcanza',
        ),
      );
      expect(find.text('El monto recibido no alcanza'), findsOneWidget);
    });

    testWidgets('muestra la ayuda debajo del campo', (tester) async {
      final controlador = TextEditingController();
      addTearDown(controlador.dispose);
      await montar(
        tester,
        CampoGip(
          etiqueta: 'Código interno',
          controlador: controlador,
          campoKey: const Key('codigo'),
          ayuda: 'El código interno no se cambia',
        ),
      );
      expect(
        tester.getTopLeft(find.text('El código interno no se cambia')).dy,
        greaterThan(tester.getBottomLeft(find.byKey(const Key('codigo'))).dy),
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

  testWidgets('PildoraEstado: verde, gris, rojo y punteada', (tester) async {
    await montar(
      tester,
      const Wrap(
        children: [
          PildoraEstado('Cuadra', tono: TonoEstado.bien),
          PildoraEstado('Se ajusta', tono: TonoEstado.neutro),
          PildoraEstado('Diferencia grande', tono: TonoEstado.error),
          PildoraEstado('Sin contar', tono: TonoEstado.pendiente),
        ],
      ),
    );
    Color? color(String texto) =>
        tester.widget<Text>(find.text(texto)).style?.color;
    expect(color('Cuadra'), ColoresGip.primarioOscuro);
    expect(color('Se ajusta'), ColoresGip.textoSecundario);
    expect(color('Diferencia grande'), ColoresGip.error);
    expect(color('Sin contar'), ColoresGip.textoSecundario);
    expect(
      find.ancestor(
        of: find.text('Sin contar'),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('TarjetaAviso: fondo y textos de error', (tester) async {
    await montar(
      tester,
      const TarjetaAviso(
        titulo: '2 diferencias grandes',
        texto: 'Vuelva a contarlas antes de confirmar.',
      ),
    );
    expect(
      tester.widget<Text>(find.text('2 diferencias grandes')).style?.color,
      ColoresGip.errorTexto,
    );
    final caja = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('2 diferencias grandes'),
            matching: find.byType(Container),
          )
          .last,
    );
    final deco = caja.decoration! as BoxDecoration;
    expect(deco.color, ColoresGip.errorFondo);
    expect(deco.border, Border.all(color: ColoresGip.errorBorde));
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('TarjetaAviso: sin texto muestra solo el título', (tester) async {
    await montar(
      tester,
      const TarjetaAviso(
        titulo: 'Esta consulta es solo para el propietario',
        icono: Icons.lock_outline,
      ),
    );
    expect(
      find.text('Esta consulta es solo para el propietario'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(TarjetaAviso),
        matching: find.byType(Text),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PildoraEstado informativa: azul de info', (tester) async {
    await montar(
      tester,
      const PildoraEstado('Provisional', tono: TonoEstado.informativo),
    );
    expect(
      tester.widget<Text>(find.text('Provisional')).style?.color,
      ColoresGip.infoTexto,
    );
    final caja = tester.widget<Container>(
      find.descendant(
        of: find.byType(PildoraEstado),
        matching: find.byType(Container),
      ),
    );
    expect((caja.decoration! as BoxDecoration).color, ColoresGip.info);
  });

  group('NotaInfo', () {
    testWidgets('fondo info, ícono y texto destacado en negrilla', (
      tester,
    ) async {
      await montar(
        tester,
        const NotaInfo(
          destacado: 'Provisional =',
          texto: 'lleva menos de 30 días de ventas; el cálculo puede cambiar.',
        ),
      );
      final caja = tester.widget<Container>(
        find.descendant(
          of: find.byType(NotaInfo),
          matching: find.byType(Container),
        ),
      );
      expect((caja.decoration! as BoxDecoration).color, ColoresGip.info);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      final rico = tester.widget<Text>(
        find.descendant(of: find.byType(NotaInfo), matching: find.byType(Text)),
      );
      final destacado =
          (rico.textSpan! as TextSpan).children!.first as TextSpan;
      expect(destacado.text, 'Provisional = ');
      expect(destacado.style?.fontWeight, FontWeight.w700);
      expect(
        rico.textSpan!.toPlainText(),
        'Provisional = lleva menos de 30 días de ventas; el cálculo puede '
        'cambiar.',
      );
    });

    testWidgets('sin destacado y sin desbordes en 360 px', (tester) async {
      await montar(
        tester,
        const NotaInfo(texto: 'Un texto largo que tiene que bajar de línea.'),
        ancho: 360,
      );
      expect(tester.takeException(), isNull);
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

  testWidgets('CampoGip resaltado: borde de error y texto a la derecha', (
    tester,
  ) async {
    final controlador = TextEditingController(text: '78');
    addTearDown(controlador.dispose);
    await montar(
      tester,
      CampoGip(
        etiqueta: '',
        controlador: controlador,
        campoKey: const Key('campo'),
        alineacion: TextAlign.end,
        resaltado: true,
      ),
    );
    final campo = tester.widget<TextField>(find.byKey(const Key('campo')));
    expect(campo.textAlign, TextAlign.end);
    final borde = campo.decoration!.enabledBorder! as OutlineInputBorder;
    expect(borde.borderSide.color, ColoresGip.error);
    expect(find.text('78'), findsOneWidget);
  });

  testWidgets('CampoGip con estiloTexto usa esa letra', (tester) async {
    final controlador = TextEditingController(text: '46');
    addTearDown(controlador.dispose);
    const estilo = TextStyle(fontSize: 20, fontWeight: FontWeight.w800);
    await montar(
      tester,
      CampoGip(
        etiqueta: '',
        controlador: controlador,
        campoKey: const Key('campo'),
        estiloTexto: estilo,
      ),
    );
    expect(
      tester.widget<TextField>(find.byKey(const Key('campo'))).style,
      estilo,
    );
  });

  testWidgets('CampoGip usa el FocusNode que recibe', (tester) async {
    final controlador = TextEditingController();
    final foco = FocusNode();
    addTearDown(controlador.dispose);
    addTearDown(foco.dispose);
    await montar(
      tester,
      CampoGip(
        etiqueta: 'Contado',
        controlador: controlador,
        focusNode: foco,
        campoKey: const Key('campo'),
      ),
    );
    await tester.tap(find.byKey(const Key('campo')));
    await tester.pump();
    expect(foco.hasFocus, isTrue);
  });

  group('SelectorFiltro', () {
    Future<List<String>> montarFiltro(
      WidgetTester tester, {
      double ancho = 390,
    }) async {
      final elegidos = <String>[];
      await montar(
        tester,
        SelectorFiltro<String>(
          opciones: const [
            (valor: 'todos', etiqueta: 'Todos'),
            (valor: 'contados', etiqueta: 'Contados'),
            (valor: 'sin', etiqueta: 'Sin contar'),
            (valor: 'dif', etiqueta: 'Con diferencia · 2'),
          ],
          elegido: 'contados',
          onElegir: elegidos.add,
        ),
        ancho: ancho,
      );
      return elegidos;
    }

    testWidgets('la elegida va rellena; tocar otra la elige', (tester) async {
      final elegidos = await montarFiltro(tester);
      final elegida = tester.widget<Material>(
        find.byKey(const Key('filtro_1')),
      );
      final otra = tester.widget<Material>(find.byKey(const Key('filtro_0')));
      expect(elegida.color, ColoresGip.navFondo);
      expect(otra.color, ColoresGip.superficie);

      await tester.tap(find.text('Sin contar'));
      expect(elegidos, ['sin']);
    });

    testWidgets('tocar una píldora no le quita el foco a un campo', (
      tester,
    ) async {
      final controlador = TextEditingController();
      final foco = FocusNode();
      addTearDown(controlador.dispose);
      addTearDown(foco.dispose);
      await montar(
        tester,
        Column(
          children: [
            TextField(controller: controlador, focusNode: foco),
            SelectorFiltro<String>(
              opciones: const [
                (valor: 'todos', etiqueta: 'Todos'),
                (valor: 'sin', etiqueta: 'Sin contar'),
              ],
              elegido: 'todos',
              onElegir: (_) {},
            ),
          ],
        ),
      );
      foco.requestFocus();
      await tester.pump();
      await tester.tap(find.text('Sin contar'));
      await tester.pump();
      expect(foco.hasFocus, isTrue);
    });

    testWidgets('pestañas: la elegida en blanco con sombra; 44 px', (
      tester,
    ) async {
      final elegidos = <String>[];
      await montar(
        tester,
        SelectorFiltro<String>(
          estilo: EstiloFiltro.pestanas,
          opciones: const [
            (valor: 'todos', etiqueta: 'Todos · 4'),
            (valor: 'sin', etiqueta: 'Sin contar · 3'),
          ],
          elegido: 'todos',
          onElegir: elegidos.add,
        ),
        ancho: 1280,
      );
      final elegida = tester.widget<Container>(
        find.byKey(const Key('filtro_0')),
      );
      final otra = tester.widget<Container>(find.byKey(const Key('filtro_1')));
      final decoElegida = elegida.decoration! as BoxDecoration;
      expect(decoElegida.color, ColoresGip.superficie);
      expect(decoElegida.boxShadow, FormaGip.sombraPestana);
      expect((otra.decoration! as BoxDecoration).color, isNull);
      expect(
        tester.widget<Text>(find.text('Sin contar · 3')).style?.color,
        ColoresGip.textoSecundario,
      );
      expect(
        tester.getSize(find.byKey(const Key('filtro_1'))).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(find.text('Sin contar · 3'));
      expect(elegidos, ['sin']);
    });

    testWidgets('píldoras de 44 px que bajan de línea sin desbordar', (
      tester,
    ) async {
      await montarFiltro(tester, ancho: 360);
      for (var i = 0; i < 4; i++) {
        expect(
          tester.getSize(find.byKey(Key('filtro_$i'))).height,
          greaterThanOrEqualTo(44),
        );
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('TarjetaCifra', () {
    testWidgets('etiqueta, valor con cifras tabulares y detalle', (
      tester,
    ) async {
      await montar(
        tester,
        const TarjetaCifra(
          etiqueta: 'Total',
          valor: r'$ 13.400',
          detalle: 'la venta',
        ),
      );
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('la venta'), findsOneWidget);
      final valor = tester.widget<Text>(find.text(r'$ 13.400'));
      expect(
        valor.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(valor.style?.color, isNot(ColoresGip.errorTexto));
    });

    testWidgets('enRojo: el valor va en errorTexto', (tester) async {
      await montar(
        tester,
        const TarjetaCifra(etiqueta: 'Falta', valor: r'$ 8.400', enRojo: true),
      );
      expect(
        tester.widget<Text>(find.text(r'$ 8.400')).style?.color,
        ColoresGip.errorTexto,
      );
    });

    testWidgets('tres en fila caben en 360 px sin desbordar', (tester) async {
      await montar(
        tester,
        const Row(
          children: [
            Expanded(
              child: TarjetaCifra(
                etiqueta: 'Total',
                valor: r'$ 1.284.000',
                detalle: 'la venta',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TarjetaCifra(
                etiqueta: 'Ya pagó',
                valor: r'$ 1.000.000',
                detalle: 'efectivo y Nequi',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TarjetaCifra(
                etiqueta: 'Falta',
                valor: r'$ 284.000',
                detalle: 'por cubrir',
                enRojo: true,
              ),
            ),
          ],
        ),
        ancho: 360,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('OpcionRadio', () {
    testWidgets('elegida: fondo primarioSuave y radio marcado; valor en rojo', (
      tester,
    ) async {
      await montar(
        tester,
        const OpcionRadio(
          titulo: 'María Pérez',
          subtitulo: '300 412 4521 · 3 fiados pendientes',
          valor: r'debe $ 47.500',
          valorEnRojo: true,
          elegida: true,
          onTap: null,
        ),
      );
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(OpcionRadio),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, ColoresGip.primarioSuave);
      expect(
        tester.widget<Text>(find.text(r'debe $ 47.500')).style?.color,
        ColoresGip.errorTexto,
      );
    });

    testWidgets('sin elegir: radio vacío, 56 px y tocar la elige', (
      tester,
    ) async {
      var tocada = 0;
      await montar(
        tester,
        OpcionRadio(
          key: const Key('opcion'),
          titulo: 'Ana',
          valor: r'$ 0',
          elegida: false,
          onTap: () => tocada++,
        ),
        ancho: 360,
      );
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('opcion'))).height,
        greaterThanOrEqualTo(56),
      );
      await tester.tap(find.text('Ana'));
      expect(tocada, 1);
    });
  });

  testWidgets('BotonDestructivo: rojo, se toca y tiene área táctil de 44 px', (
    tester,
  ) async {
    var tocado = 0;
    await montar(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: BotonDestructivo(
          texto: 'Eliminar datos del cliente',
          icono: Icons.delete_outline,
          onPressed: () => tocado++,
        ),
      ),
    );
    await tester.tap(find.text('Eliminar datos del cliente'));
    expect(tocado, 1);
    final boton = find.byType(OutlinedButton);
    expect(tester.getSize(boton).height, greaterThanOrEqualTo(44));
    final esquema = Theme.of(tester.element(boton)).colorScheme;
    final estilo = tester.widget<OutlinedButton>(boton).style!;
    expect(estilo.foregroundColor!.resolve({}), esquema.error);
  });

  group('pedirConfirmacion', () {
    Future<void> abrirDialogo(WidgetTester tester, List<bool> resultados) =>
        montar(
          tester,
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => resultados.add(
                await pedirConfirmacion(
                  context,
                  pregunta: '¿Seguro?',
                  textoConfirmar: 'Eliminar',
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        );

    testWidgets('confirmar termina con verdadero', (tester) async {
      final resultados = <bool>[];
      await abrirDialogo(tester, resultados);
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('¿Seguro?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmacion_confirmar')));
      await tester.pumpAndSettle();

      expect(resultados, [true]);
      expect(find.text('¿Seguro?'), findsNothing);
    });

    testWidgets('cancelar o tocar fuera termina con falso', (tester) async {
      final resultados = <bool>[];
      await abrirDialogo(tester, resultados);
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmacion_cancelar')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(resultados, [false, false]);
    });
  });
}
