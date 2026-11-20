import 'package:drift/drift.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/service_agents/sincronizacion/servidor_remoto.dart';
import 'package:gip/data/service_agents/sincronizacion/tablas_sincronizables.dart';

/// Lo que hace la conciliación (CUS-23): `ConciliarCoordinator.ejecutar`. El
/// Sincronizador no importa el coordinador (la Data Layer no conoce el
/// Workflow): se lo entrega el Composition Root.
typedef Conciliar = Future<List<ConflictoSincronizacion>> Function(
  Tienda tienda,
  DateTime desde,
);

/// Lo que pasó en una sincronización.
class ResultadoSincronizacion {
  const ResultadoSincronizacion({
    this.subidos = 0,
    this.bajados = 0,
    this.conflictosNuevos = const [],
    this.pendientes = 0,
    this.sinConexion = false,
    this.error,
  });

  /// Registros que se subieron al servidor.
  final int subidos;

  /// Registros que llegaron del servidor y cambiaron algo en este equipo.
  final int bajados;

  /// Conflictos que detectó la conciliación en esta vuelta (CUS-23).
  final List<ConflictoSincronizacion> conflictosNuevos;

  /// Entradas que siguen en la cola de pendientes al terminar.
  final int pendientes;

  /// No hubo conexión con el servidor: no se perdió nada, se reintenta luego.
  final bool sinConexion;

  /// Un fallo que no es de red (por ejemplo, la conciliación falló). Los
  /// pendientes siguen en la cola.
  final String? error;

  bool get termino => !sinConexion && error == null;

  @override
  String toString() =>
      'Sincronizacion(subidos: $subidos, bajados: $bajados, '
      'conflictos: ${conflictosNuevos.length}, pendientes: $pendientes, '
      'sinConexion: $sinConexion, error: $error)';
}

/// Service Agent que sube la cola de pendientes y baja los cambios de los demás
/// equipos, y al terminar dispara la conciliación (CUS-23, RNF-08, DA-33,
/// DA-48, DI-47). Funciona con cualquier [ServidorRemoto].
///
/// - **Subir.** Por cada tabla, en orden de llaves foráneas, agrupa las
///   entradas de la cola por registro, lee la fila local de ese momento y la
///   envía en lotes. Lo que el servidor acepta sale de la cola; lo que rechaza
///   queda con un intento más; si no hay red, se detiene sin perder nada.
/// - **Bajar.** Por cada tabla pide lo que el servidor cambió desde el cursor
///   (`sincronizado_en`, con un margen de unos segundos porque dos
///   transacciones pueden confirmarse en otro orden del que empezaron) y lo
///   aplica con la regla de choque de la tabla, sin anotarlo en la cola. Las
///   filas con cambios pendientes de subir no se pisan.
/// - **Conciliar.** Si algo cambió, llama a [Conciliar] con la fecha del
///   registro más antiguo que llegó; si la conciliación escribió algo, lo sube.
class Sincronizador {
  Sincronizador(
    this._base,
    this._servidor,
    this._conciliar, {
    DateTime Function()? reloj,
    this.tamanoLote = 100,
    this.tamanoPagina = 500,
    this.margenCursor = const Duration(seconds: 5),
  }) : _reloj = reloj ?? DateTime.now;

  final BaseLocalDrift _base;
  final ServidorRemoto _servidor;
  final Conciliar _conciliar;
  final DateTime Function() _reloj;

  /// Filas por petición al subir.
  final int tamanoLote;

  /// Filas por petición al bajar.
  final int tamanoPagina;

  /// Cuánto antes del cursor se vuelve a pedir, por si una transacción del
  /// servidor se confirmó después de otra que empezó más tarde. Pedir de más no
  /// hace daño: aplicar una fila repetida no cambia nada.
  final Duration margenCursor;

  static const _tablaCursorEliminados = tablaEliminados;

  Future<ResultadoSincronizacion>? _enCurso;

  /// Alguien pidió sincronizar mientras ya había una en curso: lo que cambió
  /// después de que ella empezó a leer no está en su resultado, así que al
  /// terminar se hace otra vuelta.
  bool _otraVuelta = false;

  /// Cuántas vueltas seguidas como máximo por un mismo pedido: si cada vuelta
  /// escribe algo que vuelve a pedir otra (la conciliación), no se encierra.
  static const _maximoDeVueltas = 3;

  /// Avisa cada vez que se agrega una entrada a la cola de pendientes, es
  /// decir, cada vez que este equipo escribe algo que hay que subir. Lo
  /// usa el disparador para sincronizar enseguida (DI-48). Los borrados de la
  /// cola, que hace la propia sincronización al subir, no avisan.
  Stream<void> get escrituras => _base
      .tableUpdates(
        TableUpdateQuery.onTable(
          _base.colaPendientes,
          limitUpdateKind: UpdateKind.insert,
        ),
      )
      .map((_) {});

  /// Sincroniza la tienda. Si ya hay una sincronización en curso devuelve esa
  /// misma, y al terminar hace otra vuelta para recoger lo que cambió mientras
  /// corría. Nunca lanza: lo que sale mal queda en el resultado.
  Future<ResultadoSincronizacion> sincronizar(Tienda tienda) {
    final enCurso = _enCurso;
    if (enCurso != null) {
      _otraVuelta = true;
      return enCurso;
    }
    return _enCurso = _hastaEstabilizar(tienda)
        .whenComplete(() => _enCurso = null);
  }

  Future<ResultadoSincronizacion> _hastaEstabilizar(Tienda tienda) async {
    var total = await _correr(tienda);
    var vueltas = 1;
    while (_otraVuelta && vueltas < _maximoDeVueltas && !total.sinConexion) {
      _otraVuelta = false;
      vueltas++;
      total = _sumar(total, await _correr(tienda));
    }
    _otraVuelta = false;
    return total;
  }

  static ResultadoSincronizacion _sumar(
    ResultadoSincronizacion a,
    ResultadoSincronizacion b,
  ) => ResultadoSincronizacion(
    subidos: a.subidos + b.subidos,
    bajados: a.bajados + b.bajados,
    conflictosNuevos: [...a.conflictosNuevos, ...b.conflictosNuevos],
    pendientes: b.pendientes,
    sinConexion: b.sinConexion,
    error: b.error ?? a.error,
  );

  Future<ResultadoSincronizacion> _correr(Tienda tienda) async {
    var subidos = 0;
    var bajados = 0;
    var nuevos = <ConflictoSincronizacion>[];
    String? error;
    var sinConexion = false;
    try {
      subidos += await _subir(tienda);
      final bajada = await _bajar(tienda);
      bajados = bajada.cambios;
      if (bajada.cambios > 0) {
        try {
          nuevos = await _conciliar(tienda, bajada.desde ?? _reloj().toUtc());
        } catch (e) {
          error = 'No se pudo conciliar: $e';
        }
        // Lo que escribió la conciliación (estados, saldos, conflictos) también
        // se comparte con los demás equipos.
        subidos += await _subir(tienda);
      }
    } on FalloDeRed {
      sinConexion = true;
    } catch (e) {
      error = '$e';
    }
    return ResultadoSincronizacion(
      subidos: subidos,
      bajados: bajados,
      conflictosNuevos: nuevos,
      pendientes: await _contarPendientes(tienda),
      sinConexion: sinConexion,
      error: error,
    );
  }

  // ───────────────────────────── subir ─────────────────────────────

  Future<int> _contarPendientes(Tienda tienda) async {
    final cola = _base.colaPendientes;
    final cuenta = cola.id.count();
    final fila =
        await (_base.selectOnly(cola)
              ..addColumns([cuenta])
              ..where(cola.tiendaId.equals(tienda.getId())))
            .getSingle();
    return fila.read(cuenta) ?? 0;
  }

  Future<int> _subir(Tienda tienda) async {
    final entradas =
        await (_base.select(_base.colaPendientes)
              ..where((c) => c.tiendaId.equals(tienda.getId()))
              ..orderBy([(c) => OrderingTerm.asc(c.creadoEn)]))
            .get();
    if (entradas.isEmpty) return 0;
    final porTabla = <String, List<EntradaCola>>{};
    for (final e in entradas) {
      porTabla.putIfAbsent(e.tabla, () => []).add(e);
    }
    var subidos = 0;
    for (final tabla in tablasSincronizables) {
      final deLaTabla = porTabla.remove(tabla.nombre);
      if (deLaTabla == null) continue;
      subidos += await _subirTabla(tienda, tabla, deLaTabla);
    }
    // Lo que queda es de tablas que no se sincronizan (las alertas, que cada
    // equipo calcula, DI-25): no hay nada que subir.
    for (final resto in porTabla.values) {
      await _sacarDeLaCola([for (final e in resto) e.id]);
    }
    return subidos;
  }

  Future<int> _subirTabla(
    Tienda tienda,
    TablaSincronizable tabla,
    List<EntradaCola> entradas,
  ) async {
    // Un registro puede tener varias entradas: se sube su estado de ahora.
    final porRegistro = <String, List<EntradaCola>>{};
    for (final e in entradas) {
      porRegistro.putIfAbsent(e.registroId, () => []).add(e);
    }
    final aInsertar = <_Envio>[];
    final aGuardar = <_Envio>[];
    final aBorrar = <_Envio>[];
    final descartar = <String>[];
    for (final MapEntry(key: id, value: grupo) in porRegistro.entries) {
      final ids = [for (final e in grupo) e.id];
      final operaciones = [for (final e in grupo) e.operacion];
      if (operaciones.last == OperacionCola.eliminar) {
        if (tablasConBorrado.contains(tabla.nombre)) {
          aBorrar.add(_Envio(id, ids, const {}));
        } else {
          descartar.addAll(ids);
        }
        continue;
      }
      final solo = operaciones.every((o) => o == OperacionCola.insertar);
      if (tabla.soloAlInsertar &&
          !operaciones.contains(OperacionCola.insertar)) {
        descartar.addAll(ids);
        continue;
      }
      final fila = await _leerFila(tienda, tabla, id);
      if (fila == null) {
        descartar.addAll(ids);
        continue;
      }
      (solo ? aInsertar : aGuardar).add(_Envio(id, ids, fila));
    }
    await _sacarDeLaCola(descartar);

    var subidos = 0;
    subidos += await _enviar(
      aInsertar,
      (filas) => _servidor.insertarSiNoExiste(tabla.nombre, filas),
    );
    subidos += await _enviar(
      aGuardar,
      (filas) => _servidor.guardar(tabla.nombre, filas),
    );
    for (final envio in aBorrar) {
      try {
        await _servidor.borrar(tabla.nombre, envio.id);
        await _sacarDeLaCola(envio.entradas);
        subidos++;
      } on RechazoDelServidor {
        await _contarIntento(envio.entradas);
      }
    }
    return subidos;
  }

  /// Envía en lotes. Si el servidor rechaza un lote, lo reintenta fila por fila
  /// para que una sola fila mala no frene a las demás.
  Future<int> _enviar(
    List<_Envio> envios,
    Future<void> Function(List<FilaRemota> filas) enviar,
  ) async {
    var subidos = 0;
    for (var i = 0; i < envios.length; i += tamanoLote) {
      final lote = envios.sublist(
        i,
        i + tamanoLote > envios.length ? envios.length : i + tamanoLote,
      );
      try {
        await enviar([for (final e in lote) e.fila]);
        await _sacarDeLaCola([for (final e in lote) ...e.entradas]);
        subidos += lote.length;
      } on RechazoDelServidor {
        for (final e in lote) {
          try {
            await enviar([e.fila]);
            await _sacarDeLaCola(e.entradas);
            subidos++;
          } on RechazoDelServidor {
            await _contarIntento(e.entradas);
          }
        }
      }
    }
    return subidos;
  }

  Future<FilaRemota?> _leerFila(
    Tienda tienda,
    TablaSincronizable tabla,
    String id,
  ) async {
    final filas = await _base
        .customSelect(
          tabla.sqlLeer,
          variables: [
            Variable.withString(id),
            Variable.withString(tienda.getId()),
          ],
        )
        .get();
    if (filas.isEmpty) return null;
    return tabla.aFilaServidor(filas.single.data);
  }

  Future<void> _sacarDeLaCola(List<String> ids) async {
    if (ids.isEmpty) return;
    await (_base.delete(
      _base.colaPendientes,
    )..where((c) => c.id.isIn(ids))).go();
  }

  /// Anota que el servidor rechazó estas entradas una vez más. Quedan en la
  /// cola: nunca se borra sola una escritura que no llegó (RNF-15).
  Future<void> _contarIntento(List<String> ids) async {
    final filas = await (_base.select(
      _base.colaPendientes,
    )..where((c) => c.id.isIn(ids))).get();
    for (final f in filas) {
      await (_base.update(_base.colaPendientes)
            ..where((c) => c.id.equals(f.id)))
          .write(ColaPendientesCompanion(intentos: Value(f.intentos + 1)));
    }
  }

  // ───────────────────────────── bajar ─────────────────────────────

  Future<_Bajada> _bajar(Tienda tienda) async {
    final cola = await (_base.select(
      _base.colaPendientes,
    )..where((c) => c.tiendaId.equals(tienda.getId()))).get();
    final pendientes = {for (final e in cola) '${e.tabla}|${e.registroId}'};
    final bajada = _Bajada();
    for (final tabla in tablasSincronizables) {
      await _bajarTabla(tienda, tabla.nombre, bajada, (fila) async {
        if (pendientes.contains('${tabla.nombre}|${fila['id']}')) return;
        final cambio = await _aplicar(tienda, tabla, fila);
        if (!cambio) return;
        bajada.cambios++;
        final fecha = tabla.columnaFecha == null
            ? null
            : DateTime.tryParse('${fila[tabla.columnaFecha]}');
        bajada.verFecha(fecha);
      });
    }
    await _bajarTabla(tienda, _tablaCursorEliminados, bajada, (fila) async {
      final tabla = '${fila['tabla']}';
      final id = '${fila['registro_id']}';
      if (!tablasConBorrado.contains(tabla)) return;
      if (pendientes.contains('$tabla|$id')) return;
      final borradas = await _base.customUpdate(
        'DELETE FROM $tabla WHERE id = ? AND tienda_id = ?',
        variables: [
          Variable.withString(id),
          Variable.withString(tienda.getId()),
        ],
        updates: _tablasDrift(tabla),
      );
      if (borradas > 0) bajada.cambios++;
    });
    return bajada;
  }

  /// Pide a [tabla] todo lo cambiado desde su cursor, de a páginas, y deja que
  /// [aplicar] procese cada fila dentro de una transacción. Guarda el cursor
  /// solo si toda la tabla se procesó.
  Future<void> _bajarTabla(
    Tienda tienda,
    String tabla,
    _Bajada bajada,
    Future<void> Function(FilaRemota fila) aplicar,
  ) async {
    final cursor = await _leerCursor(tienda, tabla);
    final desde = cursor == null
        ? null
        : DateTime.parse(cursor)
              .subtract(margenCursor)
              .toUtc()
              .toIso8601String();
    var mayor = cursor;
    var desplazamiento = 0;
    while (true) {
      final filas = await _servidor.leerDesde(
        tabla,
        tienda.getId(),
        desde: desde,
        limite: tamanoPagina,
        desplazamiento: desplazamiento,
      );
      await _base.transaction(() async {
        for (final fila in filas) {
          final marca = fila['sincronizado_en'];
          if (marca is String &&
              (mayor == null ||
                  DateTime.parse(marca).isAfter(DateTime.parse(mayor!)))) {
            mayor = marca;
          }
          await aplicar(fila);
        }
      });
      if (filas.length < tamanoPagina) break;
      desplazamiento += tamanoPagina;
    }
    if (mayor != null && mayor != cursor) {
      await _base
          .into(_base.cursoresSincronizacion)
          .insertOnConflictUpdate(
            CursoresSincronizacionCompanion.insert(
              tiendaId: tienda.getId(),
              tabla: tabla,
              cursor: mayor!,
            ),
          );
    }
  }

  Future<String?> _leerCursor(Tienda tienda, String tabla) async {
    final fila =
        await (_base.select(_base.cursoresSincronizacion)..where(
              (c) => c.tiendaId.equals(tienda.getId()) & c.tabla.equals(tabla),
            ))
            .getSingleOrNull();
    return fila?.cursor;
  }

  /// Aplica una fila que bajó con la regla de choque de su tabla. Verdadero si
  /// cambió algo en la base local.
  Future<bool> _aplicar(
    Tienda tienda,
    TablaSincronizable tabla,
    FilaRemota fila,
  ) async {
    final cambiadas = await _base.customUpdate(
      tabla.sqlAplicar,
      variables: [for (final v in tabla.aValoresLocales(fila)) _variable(v)],
      updates: _tablasDrift(tabla.nombre),
    );
    return cambiadas > 0;
  }

  Set<TableInfo> _tablasDrift(String nombre) => {
    for (final t in _base.allTables)
      if (t.actualTableName == nombre) t,
  };

  static Variable _variable(Object? v) => switch (v) {
    null => const Variable<String>(null),
    final int i => Variable.withInt(i),
    final String s => Variable.withString(s),
    final num n => Variable.withReal(n.toDouble()),
    final bool b => Variable.withBool(b),
    _ => Variable.withString('$v'),
  };
}

/// Un registro listo para enviar: su id, las entradas de la cola que cubre y la
/// fila de ese momento.
class _Envio {
  _Envio(this.id, this.entradas, this.fila);

  final String id;
  final List<String> entradas;
  final FilaRemota fila;
}

class _Bajada {
  int cambios = 0;
  DateTime? desde;

  /// Guarda la fecha más antigua de lo que llegó.
  void verFecha(DateTime? fecha) {
    if (fecha == null) return;
    if (desde == null || fecha.isBefore(desde!)) desde = fecha.toUtc();
  }
}
