import 'package:gip/business/componentes/info_tienda/resolutor_conflicto.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/interfaces/info_tienda/i_conflicto_repositorio.dart';

import '../gestion_inventario/fakes_catalogo.dart';

/// Conflictos en memoria, por tienda, con copia de seguridad para simular el
/// rollback. [fallarAlMarcar] simula una falla del disco.
class ConflictoRepositorioFalso implements IConflictoRepositorio, Restaurable {
  final Map<String, List<ConflictoSincronizacion>> _datos = {};
  Map<String, List<String>> _copiaResueltos = {};

  /// Ids marcados con marcarResuelto, en orden de llegada.
  final List<String> marcados = [];

  /// Para cada marcarResuelto: si había una transacción abierta.
  final List<bool> marcadosEnTransaccion = [];
  UnidadTrabajoFalsa? unidad;
  bool fallarAlMarcar = false;

  List<ConflictoSincronizacion> _de(Tienda t) =>
      _datos.putIfAbsent(t.getId(), () => []);

  /// Deja un conflicto ya guardado.
  void sembrar(Tienda tienda, ConflictoSincronizacion conflicto) =>
      _de(tienda).add(conflicto);

  /// Los ids ya resueltos de la tienda.
  List<String> resueltos(Tienda tienda) => [
    for (final c in _de(tienda))
      if (c.isResuelto()) c.getId(),
  ];

  @override
  void tomarCopia() => _copiaResueltos = {
    for (final e in _datos.entries)
      e.key: [
        for (final c in e.value)
          if (c.isResuelto()) c.getId(),
      ],
  };

  @override
  void restaurar() {
    for (final e in _datos.entries) {
      for (final c in e.value) {
        c.setResuelto((_copiaResueltos[e.key] ?? const []).contains(c.getId()));
      }
    }
  }

  @override
  Future<void> guardar(Tienda tienda, ConflictoSincronizacion conflicto) async {
    if (_de(tienda).any((c) => c.getId() == conflicto.getId())) return;
    _de(tienda).add(conflicto);
  }

  @override
  Future<List<ConflictoSincronizacion>> listarPendientes(Tienda tienda) async =>
      _de(tienda).where((c) => !c.isResuelto()).toList()
        ..sort((a, b) => a.getFecha().compareTo(b.getFecha()));

  @override
  Future<void> marcarResuelto(
    Tienda tienda,
    ConflictoSincronizacion conflicto,
  ) async {
    if (fallarAlMarcar) throw StateError('falla del disco');
    marcadosEnTransaccion.add(unidad?.abierta ?? false);
    marcados.add(conflicto.getId());
    final guardado = _de(tienda)
        .where((c) => c.getId() == conflicto.getId())
        .firstOrNull;
    guardado?.setResuelto(true);
  }
}

/// Resolutor que anota lo que recibe. Atiende los [tipos] que se le den.
class ResolutorFalso implements ResolutorConflicto {
  ResolutorFalso(this.tipos, [this.eventos]);

  final Set<TipoConflicto> tipos;

  /// Lista compartida para ver el orden entre resolutor y marcarResuelto.
  final List<String>? eventos;

  /// Cada llamada a resolver: (tienda, conflicto, idsElegidos).
  final List<(Tienda, ConflictoSincronizacion, List<String>)> llamadas = [];

  /// Si es verdadero, resolver falla (para probar el rollback).
  bool fallar = false;

  /// Para cada resolver: si había una transacción abierta.
  final List<bool> enTransaccion = [];
  UnidadTrabajoFalsa? unidad;

  @override
  bool admite(ConflictoSincronizacion conflicto) =>
      tipos.contains(conflicto.getTipo());

  @override
  Future<void> resolver(
    Tienda tienda,
    ConflictoSincronizacion conflicto,
    List<String> idsElegidos,
  ) async {
    enTransaccion.add(unidad?.abierta ?? false);
    llamadas.add((tienda, conflicto, idsElegidos));
    eventos?.add('resolver');
    if (fallar) throw StateError('falla del resolutor');
  }
}
