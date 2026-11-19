import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:gip/business/entidades/info_tienda/conflicto_sincronizacion.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';
import 'package:gip/business/interfaces/info_tienda/i_conflicto_repositorio.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/data/local/base_local_drift.dart';

/// [IConflictoRepositorio] sobre la base local (drift), en la tabla
/// `conflictos_sincronizacion` (CUS-22, DI-45). Toda consulta filtra por
/// `tienda_id`. Cada escritura se anota en `cola_pendientes` en la misma
/// transacción (DA-33).
class ConflictoRepositorioDrift implements IConflictoRepositorio {
  ConflictoRepositorioDrift(this._base);

  final BaseLocalDrift _base;

  static const _tabla = 'conflictos_sincronizacion';

  /// Nombres que comparte con el enum `tipo_conflicto` de Supabase.
  static const _tipos = {
    TipoConflicto.stockNegativo: 'STOCK_NEGATIVO',
    TipoConflicto.abonoExcedeSaldo: 'ABONO_EXCEDE_SALDO',
    TipoConflicto.codigoRepetido: 'CODIGO_REPETIDO',
    TipoConflicto.posibleDuplicado: 'POSIBLE_DUPLICADO',
    TipoConflicto.movimientoCajaCerrada: 'MOVIMIENTO_CAJA_CERRADA',
  };

  /// Inserta el conflicto si su id no existe y, solo entonces, lo anota en
  /// `cola_pendientes` (dos dispositivos pueden detectar el mismo choque, DA-48).
  /// Si ya existe no lo toca, ni siquiera si ya estaba resuelto. Se une a la
  /// transacción abierta.
  @override
  Future<void> guardar(Tienda tienda, ConflictoSincronizacion conflicto) =>
      _base.transaction(() async {
        final existe = await (_base.select(
          _base.conflictosSincronizacion,
        )..where((c) => c.id.equals(conflicto.getId()))).getSingleOrNull();
        if (existe != null) return;
        await _base
            .into(_base.conflictosSincronizacion)
            .insert(
              ConflictosSincronizacionCompanion.insert(
                id: conflicto.getId(),
                tiendaId: tienda.getId(),
                tipo: _tipos[conflicto.getTipo()]!,
                descripcion: conflicto.getDescripcion(),
                idsRegistros: jsonEncode(conflicto.getIdsRegistros()),
                etiquetasRegistros: jsonEncode(
                  conflicto.getEtiquetasRegistros(),
                ),
                fecha: conflicto.getFecha(),
                resuelto: Value(conflicto.isResuelto()),
              ),
            );
        await anotarEnCola(
          _base,
          tiendaId: tienda.getId(),
          tabla: _tabla,
          registroId: conflicto.getId(),
          operacion: OperacionCola.insertar,
        );
      });

  /// Conflictos sin resolver de la tienda, del más antiguo al más reciente.
  @override
  Future<List<ConflictoSincronizacion>> listarPendientes(Tienda tienda) async {
    final filas =
        await (_base.select(_base.conflictosSincronizacion)
              ..where(
                (c) =>
                    c.tiendaId.equals(tienda.getId()) &
                    c.resuelto.equals(false),
              )
              ..orderBy([
                (c) => OrderingTerm.asc(c.fecha),
                (c) => OrderingTerm.asc(c.id),
              ]))
            .get();
    final tipos = _tipos.map((k, v) => MapEntry(v, k));
    return [
      for (final f in filas)
        ConflictoSincronizacion(
          f.id,
          tipos[f.tipo]!,
          f.descripcion,
          _lista(f.idsRegistros),
          f.fecha,
          etiquetasRegistros: _lista(f.etiquetasRegistros),
          resuelto: f.resuelto,
        ),
    ];
  }

  /// Guarda solo que el conflicto fue resuelto y lo anota en `cola_pendientes`
  /// como ACTUALIZAR en la misma transacción (DA-33). Se une a la transacción
  /// abierta.
  @override
  Future<void> marcarResuelto(
    Tienda tienda,
    ConflictoSincronizacion conflicto,
  ) => _base.transaction(() async {
    await (_base.update(_base.conflictosSincronizacion)..where(
          (c) =>
              c.id.equals(conflicto.getId()) &
              c.tiendaId.equals(tienda.getId()),
        ))
        .write(const ConflictosSincronizacionCompanion(resuelto: Value(true)));
    await anotarEnCola(
      _base,
      tiendaId: tienda.getId(),
      tabla: _tabla,
      registroId: conflicto.getId(),
      operacion: OperacionCola.actualizar,
    );
  });

  static List<String> _lista(String json) =>
      (jsonDecode(json) as List<dynamic>).cast<String>();
}
