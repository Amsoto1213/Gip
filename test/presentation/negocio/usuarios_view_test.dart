import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/presentation/comun/botones_gip.dart';
import 'package:gip/presentation/comun/pildora_estado.dart';
import 'package:gip/presentation/comun/tema/tema_gip.dart';
import 'package:gip/presentation/negocio/usuarios_view.dart';
import 'package:gip/presentation/negocio/usuarios_view_model.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/errores_usuarios.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'datos_alertas.dart';
import 'usuarios_falsos.dart';

void main() {
  const movil = Size(360, 640);
  const web = Size(1280, 800);

  final carmen = propietariaAlertas.usuario;
  final luis = Empleado(
    'u2',
    'Luis Gómez',
    '1000000002',
    correo: 'luis@gip.test',
  );
  final ana = Empleado('u3', 'Ana Torres', '1000000003', activo: false);

  late GestionarUsuariosFalso coordinador;

  setUpAll(() {
    registerFallbackValue(tiendaAlertas);
    registerFallbackValue(carmen);
  });

  Future<void> abrir(
    WidgetTester tester,
    Size tamano, {
    UsuarioActivo? usuario,
    List<Usuario>? lista,
    Object? errorAlListar,
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    coordinador = GestionarUsuariosFalso();
    when(() => coordinador.listarUsuarios(any(), any())).thenAnswer((i) async {
      if (errorAlListar != null) throw errorAlListar;
      if (i.positionalArguments[1] == empleadoAlertas.usuario) {
        throw const ExcepcionSoloPropietario();
      }
      return lista ?? [carmen, luis, ana];
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaGip.claro(),
        home: ChangeNotifierProvider(
          create: (_) =>
              UsuariosViewModel(coordinador, usuario ?? propietariaAlertas)
                ..cargar(),
          child: const UsuariosView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Escribe los cuatro campos del formulario.
  Future<void> escribir(
    WidgetTester tester, {
    String nombre = '',
    String cedula = '',
    String correo = '',
    String clave = '',
  }) async {
    for (final (campo, texto) in [
      ('nombre', nombre),
      ('cedula', cedula),
      ('correo', correo),
      ('clave', clave),
    ]) {
      await tester.enterText(find.byKey(Key('usuarios_$campo')), texto);
    }
  }

  /// Lleva el botón a la vista (la lista se arma por partes) y deja que se
  /// asiente antes de tocarlo.
  Future<void> verAgregar(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('usuarios_agregar')));
    await tester.pumpAndSettle();
  }

  Finder desactivar(Usuario u) =>
      find.byKey(Key('usuario_desactivar_${u.getId()}'));

  for (final (nombre, tamano) in [('móvil', movil), ('web', web)]) {
    testWidgets('$nombre: muestra activos e inactivos y el formulario', (
      tester,
    ) async {
      await abrir(tester, tamano);

      expect(tester.takeException(), isNull);
      expect(find.text('Usuarios de la tienda'), findsWidgets);
      expect(find.textContaining('Carmen'), findsOneWidget);
      expect(find.text('Luis Gómez'), findsOneWidget);
      expect(find.text('Ana Torres'), findsOneWidget);
      expect(find.text('Agregar empleado'), findsNWidgets(2));
      expect(find.text('Nombre completo'), findsOneWidget);
      expect(find.text('Cédula'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(UsuariosView.notaEmpleado),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(UsuariosView.notaEmpleado), findsOneWidget);
    });

    testWidgets('$nombre: la lista muestra el correo con el que entra cada '
        'usuario', (tester) async {
      await abrir(tester, tamano);

      expect(find.text('luis@gip.test'), findsOneWidget);
      // Carmen y Ana no tienen correo en los datos de prueba.
      expect(find.byKey(const Key('usuario_correo_u2')), findsOneWidget);
    });

    testWidgets('$nombre: solo el empleado activo tiene Desactivar', (
      tester,
    ) async {
      await abrir(tester, tamano);

      expect(desactivar(luis), findsOneWidget);
      expect(desactivar(carmen), findsNothing);
      expect(desactivar(ana), findsNothing);
    });

    testWidgets('$nombre: Activo y Inactivo van como estados', (tester) async {
      await abrir(tester, tamano);

      final pildoras = tester
          .widgetList<PildoraEstado>(find.byType(PildoraEstado))
          .toList();
      // Móvil: el empleado activo muestra su botón en lugar de la píldora.
      // Web: la tabla tiene la píldora de todos, y además el botón.
      final esperado = tamano == web
          ? ['Activo', 'Activo', 'Inactivo']
          : ['Activo', 'Inactivo'];
      expect(pildoras.map((p) => p.texto), esperado);
      expect(pildoras.first.tono, TonoEstado.bien);
      expect(pildoras.last.tono, TonoEstado.neutro);
    });

    testWidgets(
      '$nombre: Desactivar, el botón y los campos miden 44 px o más',
      (tester) async {
        await abrir(tester, tamano);

        expect(
          tester.getSize(desactivar(luis)).height,
          greaterThanOrEqualTo(44),
        );
        for (final clave in [
          'usuarios_nombre',
          'usuarios_cedula',
          'usuarios_correo',
          'usuarios_clave',
        ]) {
          expect(
            tester.getSize(find.byKey(Key(clave))).height,
            greaterThanOrEqualTo(44),
            reason: clave,
          );
        }
        await verAgregar(tester);
        expect(
          tester.getSize(find.byKey(const Key('usuarios_agregar'))).height,
          greaterThanOrEqualTo(44),
        );
      },
    );

    testWidgets('$nombre: pide confirmación y Cancelar no desactiva', (
      tester,
    ) async {
      await abrir(tester, tamano);

      await tester.tap(desactivar(luis));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dialogo_confirmacion')), findsOneWidget);
      expect(find.textContaining('Luis Gómez?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmacion_cancelar')));
      await tester.pumpAndSettle();

      verifyNever(() => coordinador.desactivarUsuario(any(), any(), any()));
      expect(find.byKey(const Key('usuarios_listo')), findsNothing);
    });

    testWidgets('$nombre: confirmar desactiva y avisa', (tester) async {
      await abrir(tester, tamano);
      when(() => coordinador.desactivarUsuario(any(), any(), any()))
          .thenAnswer((_) async {});

      await tester.tap(desactivar(luis));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmacion_confirmar')));
      await tester.pumpAndSettle();

      final args = verify(
        () => coordinador.desactivarUsuario(
          captureAny(),
          captureAny(),
          captureAny(),
        ),
      ).captured;
      expect(args, [tiendaAlertas, luis, carmen]);
      expect(find.text('Empleado desactivado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$nombre: agregar crea el empleado, avisa y limpia', (
      tester,
    ) async {
      await abrir(tester, tamano);
      when(
        () =>
            coordinador.crearEmpleado(any(), any(), any(), any(), any(), any()),
      ).thenAnswer((_) async => Empleado('u9', 'Daniel Mendoza', '1045678901'));

      await escribir(
        tester,
        nombre: 'Daniel Mendoza',
        cedula: '1045678901',
        correo: 'daniel@gip.test',
        clave: 'gip12345',
      );
      await verAgregar(tester);
      await tester.tap(find.byKey(const Key('usuarios_agregar')));
      await tester.pumpAndSettle();

      final args = verify(
        () => coordinador.crearEmpleado(
          captureAny(),
          captureAny(),
          captureAny(),
          captureAny(),
          captureAny(),
          captureAny(),
        ),
      ).captured;
      expect(args, [
        tiendaAlertas,
        'Daniel Mendoza',
        '1045678901',
        'daniel@gip.test',
        'gip12345',
        carmen,
      ]);
      expect(find.text('Empleado creado'), findsOneWidget);
      for (final campo in ['nombre', 'cedula', 'correo', 'clave']) {
        expect(
          tester
              .widget<TextField>(find.byKey(Key('usuarios_$campo')))
              .controller!
              .text,
          isEmpty,
          reason: campo,
        );
      }
    });

    testWidgets('$nombre: datos no válidos muestra el mensaje y conserva lo '
        'escrito', (tester) async {
      await abrir(tester, tamano);
      when(
        () =>
            coordinador.crearEmpleado(any(), any(), any(), any(), any(), any()),
      ).thenThrow(const ExcepcionDatosUsuarioNoValidos());

      await tester.enterText(find.byKey(const Key('usuarios_nombre')), 'Ana');
      await tester.enterText(
        find.byKey(const Key('usuarios_cedula')),
        '1000000001',
      );
      await verAgregar(tester);
      await tester.tap(find.byKey(const Key('usuarios_agregar')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'El nombre es obligatorio y la cédula no puede estar repetida',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('usuarios_listo')), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('usuarios_nombre')))
            .controller!
            .text,
        'Ana',
      );
    });

    testWidgets('$nombre: la cédula solo acepta números', (tester) async {
      await abrir(tester, tamano);

      await tester.enterText(
        find.byKey(const Key('usuarios_cedula')),
        '10a4-5 6',
      );

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('usuarios_cedula')))
            .controller!
            .text,
        '1045'
        '6',
      );
    });

    testWidgets('$nombre: el correo es de teclado de correo y la contraseña va '
        'oculta', (tester) async {
      await abrir(tester, tamano);

      final correo = tester.widget<TextField>(
        find.byKey(const Key('usuarios_correo')),
      );
      expect(correo.keyboardType, TextInputType.emailAddress);
      final clave = tester.widget<TextField>(
        find.byKey(const Key('usuarios_clave')),
      );
      expect(clave.obscureText, isTrue);
      expect(
        find.text('Con este correo y su contraseña el empleado entra a GIP.'),
        findsOneWidget,
      );
    });

    testWidgets('$nombre: el correo no válido y la contraseña corta muestran '
        'su mensaje y conservan lo escrito', (tester) async {
      await abrir(tester, tamano);
      when(
        () =>
            coordinador.crearEmpleado(any(), any(), any(), any(), any(), any()),
      ).thenThrow(const ExcepcionCorreoNoValido());

      await escribir(
        tester,
        nombre: 'Ana',
        cedula: '3',
        correo: 'sin-arroba',
        clave: 'gip12345',
      );
      await verAgregar(tester);
      await tester.tap(find.byKey(const Key('usuarios_agregar')));
      await tester.pumpAndSettle();

      expect(find.text('Escribe un correo válido'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('usuarios_correo')))
            .controller!
            .text,
        'sin-arroba',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('usuarios_clave')))
            .controller!
            .text,
        'gip12345',
      );
    });

    testWidgets('$nombre: el empleado ve que es solo del propietario y no '
        'hay formulario', (tester) async {
      await abrir(tester, tamano, usuario: empleadoAlertas);

      expect(
        find.text('Esta consulta es solo para el propietario'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('usuarios_formulario')), findsNothing);
      expect(find.text('Luis Gómez'), findsNothing);
    });

    testWidgets('$nombre: sin internet lo dice y no hay formulario', (
      tester,
    ) async {
      await abrir(
        tester,
        tamano,
        errorAlListar: const ExcepcionSinConexionUsuarios(),
      );

      expect(
        find.text('Necesitas internet para ver y cambiar los usuarios'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('usuarios_formulario')), findsNothing);
    });
  }

  testWidgets(
    'móvil: tras un error, el aviso y el formulario siguen a la vista',
    (tester) async {
      await abrir(tester, movil);
      when(
        () =>
            coordinador.crearEmpleado(any(), any(), any(), any(), any(), any()),
      ).thenThrow(const ExcepcionDatosUsuarioNoValidos());

      await tester.enterText(find.byKey(const Key('usuarios_nombre')), '');
      await verAgregar(tester);
      await tester.tap(find.byKey(const Key('usuarios_agregar')));
      await tester.pumpAndSettle();

      final aviso = tester.getRect(find.byKey(const Key('usuarios_error')));
      final campo = tester.getRect(find.byKey(const Key('usuarios_nombre')));
      expect(aviso.top, greaterThanOrEqualTo(0));
      expect(aviso.bottom, lessThan(movil.height));
      expect(aviso.bottom, lessThanOrEqualTo(campo.top));
      expect(campo.bottom, lessThan(movil.height));
    },
  );

  testWidgets('móvil: "usted" va en el rol del propietario', (tester) async {
    await abrir(tester, movil);

    expect(find.text('Propietario · usted'), findsOneWidget);
    expect(find.text('Empleado'), findsNWidgets(2));
  });

  testWidgets('móvil: el formulario va debajo de la lista, en una columna', (
    tester,
  ) async {
    await abrir(tester, movil);

    final lista = tester.getRect(find.byKey(const Key('usuarios_lista')));
    final formulario = tester.getRect(
      find.byKey(const Key('usuarios_formulario')),
    );
    expect(formulario.top, greaterThanOrEqualTo(lista.bottom));
    expect(find.text('Rol'), findsNothing);
  });

  testWidgets('web: tabla con Nombre, Rol y Estado, y "(usted)"', (
    tester,
  ) async {
    await abrir(tester, web);

    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Rol'), findsOneWidget);
    expect(find.text('Estado'), findsOneWidget);
    // "Correo" también es la etiqueta del formulario: se mira solo la tabla.
    expect(
      find.descendant(
        of: find.byKey(const Key('usuarios_lista')),
        matching: find.text('Correo'),
      ),
      findsOneWidget,
    );
    expect(find.text('Carmen (usted)', findRichText: true), findsOneWidget);
    expect(find.text('Propietario'), findsOneWidget);
    expect(find.text('Empleado'), findsNWidgets(2));
  });

  testWidgets('web: la lista a la izquierda y el formulario a la derecha', (
    tester,
  ) async {
    await abrir(tester, web);

    final lista = tester.getRect(find.byKey(const Key('usuarios_lista')));
    final formulario = tester.getRect(
      find.byKey(const Key('usuarios_formulario')),
    );
    expect(formulario.left, greaterThan(lista.right));
    expect(formulario.top, lista.top);
    expect(find.text(UsuariosView.notaDesactivar), findsOneWidget);
  });

  testWidgets('mientras guarda, bloquea el botón y los campos', (tester) async {
    await abrir(tester, web);
    final espera = Completer<Empleado>();
    when(
      () => coordinador.crearEmpleado(any(), any(), any(), any(), any(), any()),
    ).thenAnswer((_) => espera.future);

    await tester.enterText(find.byKey(const Key('usuarios_nombre')), 'Ana');
    await tester.enterText(find.byKey(const Key('usuarios_cedula')), '123');
    await tester.tap(find.byKey(const Key('usuarios_agregar')));
    await tester.pump();

    expect(
      tester
          .widget<BotonPrimario>(find.byKey(const Key('usuarios_agregar')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('usuarios_nombre')))
          .enabled,
      isFalse,
    );
    expect(desactivar(luis), findsOneWidget);
    expect(tester.widget<BotonSecundario>(desactivar(luis)).onPressed, isNull);

    espera.complete(Empleado('u9', 'Ana', '123'));
    await tester.pumpAndSettle();
    expect(find.text('Empleado creado'), findsOneWidget);
  });
}
