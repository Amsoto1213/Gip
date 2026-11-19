import 'package:flutter_test/flutter_test.dart';
import 'package:gip/business/componentes/info_tienda/servicio_acceso.dart';
import 'package:gip/business/componentes/info_tienda/servicio_conciliacion.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/entidades/info_tienda/usuario.dart';
import 'package:gip/business/interfaces/info_tienda/i_autenticacion.dart';
import 'package:gip/business/interfaces/info_tienda/i_sesion_local.dart';
import 'package:gip/business/workflow/info_tienda/revisar_conflictos_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/errores_conciliacion.dart';
import 'package:mocktail/mocktail.dart';

import '../../componentes/gestion_inventario/fakes_catalogo.dart';
import '../../componentes/info_tienda/fakes_conciliacion.dart';

class AutenticacionFalsa extends Mock implements IAutenticacion {}

class SesionLocalFalsa extends Mock implements ISesionLocal {}

/// CUS-22: solo el propietario revisa y resuelve los conflictos (RNF-12).
void main() {
  final tienda = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');
  final carmen = Administrador('u1', 'Carmen', '1000000001');
  final luis = Empleado('u2', 'Luis', '1000000002');

  late ConflictoRepositorioFalso conflictos;
  late ResolutorFalso resolutor;
  late ConflictoSincronizacion duplicado;
  late RevisarConflictosCoordinator coordinador;

  setUp(() {
    conflictos = ConflictoRepositorioFalso();
    final unidad = UnidadTrabajoFalsa([conflictos]);
    conflictos.unidad = unidad;
    resolutor = ResolutorFalso({TipoConflicto.posibleDuplicado})
      ..unidad = unidad;
    duplicado = ConflictoSincronizacion(
      'd1',
      TipoConflicto.posibleDuplicado,
      'Dos entradas iguales',
      ['m1', 'm2'],
      DateTime.utc(2026, 11, 19, 15),
    );
    conflictos.sembrar(tienda, duplicado);
    coordinador = RevisarConflictosCoordinator(
      ServicioConciliacion(conflictos, unidad, [resolutor]),
      ServicioAcceso(AutenticacionFalsa(), SesionLocalFalsa()),
    );
  });

  group('el propietario', () {
    test('consulta los conflictos pendientes', () async {
      final lista = await coordinador.consultarConflictos(tienda, carmen);

      expect(lista, [duplicado]);
    });

    test('resuelve un conflicto con su decisión', () async {
      await coordinador.resolver(tienda, duplicado, ['m2'], carmen);

      expect(resolutor.llamadas.single.$3, ['m2']);
      expect(duplicado.isResuelto(), isTrue);
      expect(await coordinador.consultarConflictos(tienda, carmen), isEmpty);
    });

    test('los errores del servicio llegan tal cual', () async {
      await coordinador.resolver(tienda, duplicado, [], carmen);

      await expectLater(
        coordinador.resolver(tienda, duplicado, [], carmen),
        throwsA(isA<ExcepcionConflictoYaResuelto>()),
      );
    });
  });

  group('el empleado no puede: acceso denegado y no se lee ni cambia nada', () {
    test('consultar', () async {
      await expectLater(
        coordinador.consultarConflictos(tienda, luis),
        throwsA(isA<ExcepcionSoloPropietario>()),
      );
    });

    test('resolver', () async {
      await expectLater(
        coordinador.resolver(tienda, duplicado, ['m2'], luis),
        throwsA(isA<ExcepcionSoloPropietario>()),
      );

      expect(resolutor.llamadas, isEmpty);
      expect(conflictos.marcados, isEmpty);
      expect(duplicado.isResuelto(), isFalse);
    });
  });
}
