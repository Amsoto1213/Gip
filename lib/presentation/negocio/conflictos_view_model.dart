import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/info_tienda/revisar_conflictos_coordinator.dart';
import 'package:gip/presentation/negocio/agrupar_conflictos.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Un registro de un conflicto, tal como lo muestra la pantalla.
typedef RegistroConflicto = ({String id, String etiqueta});

/// Estado de la pantalla Revisar sincronización (CUS-22). Llama solo a
/// [RevisarConflictosCoordinator]. Después de cada intento de resolver vuelve
/// a leer la lista (DI-42, DI-45).
///
/// Qué significan las casillas depende del tipo (DI-45):
/// - POSIBLE_DUPLICADO: las marcadas **sí ocurrieron**; al servicio le llegan
///   las no marcadas, que se anulan. Hace falta marcar al menos una.
/// - ABONO_EXCEDE_SALDO: las marcadas son los abonos **que se anulan**.
/// - CODIGO_REPETIDO: las marcadas son los productos **que pierden el código**.
/// - STOCK_NEGATIVO y MOVIMIENTO_CAJA_CERRADA: no hay casillas; se acepta como
///   está o se corrige con un conteo.
///
/// Una misma entrada registrada varias veces son varios conflictos por dentro
/// (uno por cada repetida) pero **una sola tarjeta**: [conflictos] devuelve el
/// primero de cada grupo, las casillas juntan todas las entradas y la decisión
/// se aplica a cada conflicto del grupo (DI-51).
class ConflictosViewModel extends ChangeNotifier {
  ConflictosViewModel(this._coordinador, this._usuarioActivo);

  /// Mensaje del diagrama cuando no es el propietario (CUS-05, paso 7).
  static const mensajeSoloPropietario =
      'Esta consulta es solo para el propietario';

  /// Paso 25 de CUS-22.
  static const mensajeResuelto = 'Conflicto resuelto';

  static const _mensajeFalla =
      'No se pudo guardar la decisión. Intente de nuevo';

  final RevisarConflictosCoordinator _coordinador;
  final UsuarioActivo _usuarioActivo;

  bool _cargando = false;
  bool _ocupado = false;
  String? _errorCarga;
  String? _error;
  String? _mensajeListo;
  List<List<ConflictoSincronizacion>> _grupos = const [];
  final Map<String, Set<String>> _marcados = {};

  bool get cargando => _cargando;

  /// Guardando una decisión: se bloquean los botones.
  bool get ocupado => _ocupado;

  /// No se pudo leer la lista (no es el propietario, falla del disco…).
  String? get errorCarga => _errorCarga;

  /// No se pudo aplicar la decisión; es el mensaje del tendero.
  String? get error => _error;

  /// "Conflicto resuelto".
  String? get mensajeListo => _mensajeListo;

  /// Una tarjeta por situación, del más antiguo al más reciente: el primer
  /// conflicto de cada grupo (DI-51).
  List<ConflictoSincronizacion> get conflictos => [
    for (final g in _grupos) g.first,
  ];

  /// Los conflictos que decide la tarjeta de [c]: él solo, o todos los de su
  /// grupo si es una entrada repetida varias veces.
  List<ConflictoSincronizacion> _grupoDe(ConflictoSincronizacion c) =>
      _grupos.where((g) => g.first.getId() == c.getId()).firstOrNull ?? [c];

  /// Cuántas entradas iguales hay en la tarjeta de [c] (1 si no es un grupo).
  int cantidadDeRegistros(ConflictoSincronizacion c) {
    final grupo = _grupoDe(c);
    return grupo.length == 1
        ? c.getIdsRegistros().length
        : _idsUnicos(grupo).length;
  }

  /// Lo que se le explica al tendero: la descripción del conflicto, o una que
  /// cuente todas las entradas si la tarjeta junta varias parejas.
  String descripcionDe(ConflictoSincronizacion c) {
    final grupo = _grupoDe(c);
    if (grupo.length == 1) return c.getDescripcion();
    return 'Hay ${_idsUnicos(grupo).length} entradas iguales, con la misma '
        'cantidad y factura. Puede que alguna se haya registrado más de una '
        'vez.';
  }

  /// Ids de las entradas de un grupo, sin repetir, en orden de aparición.
  List<String> _idsUnicos(List<ConflictoSincronizacion> grupo) => [
    ...{for (final c in grupo) ...c.getIdsRegistros()},
  ];

  /// Los registros del conflicto sobre los que el propietario decide con
  /// casillas. En ABONO_EXCEDE_SALDO el primero es el fiado y no se elige; en
  /// STOCK_NEGATIVO y MOVIMIENTO_CAJA_CERRADA no hay nada que marcar.
  List<RegistroConflicto> registrosElegibles(ConflictoSincronizacion c) {
    final grupo = _grupoDe(c);
    if (grupo.length > 1) {
      final etiquetas = <String, String>{};
      for (final miembro in grupo) {
        for (final id in miembro.getIdsRegistros()) {
          etiquetas.putIfAbsent(id, () => miembro.getEtiquetaDe(id) ?? id);
        }
      }
      return [
        for (final e in etiquetas.entries) (id: e.key, etiqueta: e.value),
      ];
    }
    final ids = c.getIdsRegistros();
    final etiquetas = c.getEtiquetasRegistros();
    final desde = switch (c.getTipo()) {
      TipoConflicto.posibleDuplicado || TipoConflicto.codigoRepetido => 0,
      TipoConflicto.abonoExcedeSaldo => 1,
      TipoConflicto.stockNegativo ||
      TipoConflicto.movimientoCajaCerrada => ids.length,
    };
    return [
      for (var i = desde; i < ids.length; i++)
        (id: ids[i], etiqueta: etiquetas[i]),
    ];
  }

  bool estaMarcado(ConflictoSincronizacion c, String idRegistro) =>
      _marcados[c.getId()]?.contains(idRegistro) ?? false;

  /// Marca o desmarca una casilla; no consulta ni guarda nada.
  void marcar(ConflictoSincronizacion c, String idRegistro, bool marcado) {
    final set = _marcados.putIfAbsent(c.getId(), () => <String>{});
    if (marcado) {
      set.add(idRegistro);
    } else {
      set.remove(idRegistro);
    }
    notifyListeners();
  }

  /// Verdadero si la decisión de las casillas ya se puede guardar: hace falta
  /// marcar al menos una (DI-45).
  bool puedeGuardarDecision(ConflictoSincronizacion c) =>
      !_ocupado && (_marcados[c.getId()]?.isNotEmpty ?? false);

  Future<void> cargar() async {
    _cargando = true;
    _errorCarga = null;
    notifyListeners();
    try {
      _grupos = agruparConflictos(
        await _coordinador.consultarConflictos(
          _usuarioActivo.tienda,
          _usuarioActivo.usuario,
        ),
      );
      _olvidarMarcasViejas();
    } catch (e) {
      _grupos = const [];
      _errorCarga = _texto(e);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Guarda la decisión de las casillas (CUS-22, paso 12). Qué ids viajan al
  /// servicio depende del tipo: ver la descripción de la clase. En una tarjeta
  /// de varias parejas, cada conflicto recibe lo suyo: de sus dos entradas, las
  /// que no están marcadas.
  Future<void> guardarDecision(ConflictoSincronizacion c) {
    final marcados = _marcados[c.getId()] ?? const <String>{};
    final grupo = _grupoDe(c);
    if (c.getTipo() == TipoConflicto.posibleDuplicado) {
      return _resolver([
        for (final miembro in grupo)
          (
            miembro,
            [
              for (final id in miembro.getIdsRegistros())
                if (!marcados.contains(id)) id,
            ],
          ),
      ], c);
    }
    final elegibles = registrosElegibles(c).map((r) => r.id);
    return _resolver([
      (
        c,
        [
          for (final id in elegibles)
            if (marcados.contains(id)) id,
        ],
      ),
    ], c);
  }

  /// Resuelve sin escoger nada: "Son registros distintos", "Aceptar así" y
  /// "Aceptar y recalcular". En una tarjeta de varias parejas, a todas.
  Future<void> resolverSinElegir(ConflictoSincronizacion c) => _resolver([
    for (final miembro in _grupoDe(c)) (miembro, const <String>[]),
  ], c);

  Future<void> _resolver(
    List<(ConflictoSincronizacion, List<String>)> decisiones,
    ConflictoSincronizacion tarjeta,
  ) async {
    if (_ocupado) return;
    _ocupado = true;
    _error = null;
    _mensajeListo = null;
    notifyListeners();
    try {
      for (final (conflicto, ids) in decisiones) {
        await _coordinador.resolver(
          _usuarioActivo.tienda,
          conflicto,
          ids,
          _usuarioActivo.usuario,
        );
      }
      _mensajeListo = mensajeResuelto;
      _marcados.remove(tarjeta.getId());
    } catch (e) {
      _error = _texto(e);
    }
    try {
      _grupos = agruparConflictos(
        await _coordinador.consultarConflictos(
          _usuarioActivo.tienda,
          _usuarioActivo.usuario,
        ),
      );
      _errorCarga = null;
      _olvidarMarcasViejas();
    } catch (_) {
      // Si no se pudo releer, se deja la lista que había y el aviso del
      // intento; arrastrar para actualizar vuelve a intentarlo.
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  void _olvidarMarcasViejas() {
    final vigentes = {for (final g in _grupos) g.first.getId()};
    _marcados.removeWhere((id, _) => !vigentes.contains(id));
  }

  static String _texto(Object e) => switch (e) {
    ExcepcionSoloPropietario() => mensajeSoloPropietario,
    ExcepcionNegocio() => e.mensaje,
    _ => _mensajeFalla,
  };
}
