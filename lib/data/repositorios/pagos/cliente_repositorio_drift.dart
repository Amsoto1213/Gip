import 'package:drift/drift.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/interfaces/pagos/i_cliente_repositorio.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/pagos/mapeo_fiado.dart';
import 'package:gip/transversal/texto/normalizar_texto.dart';

/// [IClienteRepositorio] sobre la base local (drift).
class ClienteRepositorioDrift implements IClienteRepositorio {
  ClienteRepositorioDrift(this._base);

  final BaseLocalDrift _base;

  static const _tabla = 'clientes';

  /// Clientes (sin los eliminados, CUS-21) cuyo `nombre_normalizado` contiene el texto normalizado (sin
  /// mayúsculas ni tildes, RD-08), por nombre, cada uno con sus fiados del más
  /// reciente al más antiguo, y los abonos de cada fiado, del más antiguo al
  /// más reciente (CUS-08).
  @override
  Future<List<Cliente>> buscarPorNombre(Tienda tienda, String texto) async {
    final patron = '%${_escaparLike(normalizarTexto(texto))}%';
    final filas =
        await (_base.select(_base.clientes)
              ..where(
                (c) =>
                    c.tiendaId.equals(tienda.getId()) &
                    c.eliminadoEn.isNull() &
                    c.nombreNormalizado.like(patron, escapeChar: r'\'),
              )
              ..orderBy([(c) => OrderingTerm.asc(c.nombreNormalizado)]))
            .get();
    if (filas.isEmpty) return const [];

    final clientes = {
      for (final f in filas) f.id: Cliente(f.id, f.nombre, f.telefono),
    };
    final fiados =
        await (_base.select(_base.fiados)
              ..where(
                (f) =>
                    f.tiendaId.equals(tienda.getId()) &
                    f.clienteId.isIn(clientes.keys),
              )
              ..orderBy([(f) => OrderingTerm.desc(f.fechaInicio)]))
            .get();
    final abonos = fiados.isEmpty
        ? <FilaAbono>[]
        : await (_base.select(_base.abonos)
                ..where(
                  (a) =>
                      a.tiendaId.equals(tienda.getId()) &
                      a.fiadoId.isIn(fiados.map((f) => f.id)),
                )
                ..orderBy([(a) => OrderingTerm.asc(a.fecha)]))
              .get();
    for (final fila in fiados) {
      final cliente = clientes[fila.clienteId]!;
      cliente.agregarFiado(
        MapeoFiado.aEntidad(
          fila,
          cliente,
          abonos.where((a) => a.fiadoId == fila.id).toList(),
        ),
      );
    }
    return clientes.values.toList();
  }

  /// Crea o actualiza el cliente con `actualizado_en` = ahora (DA-48) y lo
  /// anota en `cola_pendientes` en la misma transacción (DA-33).
  @override
  Future<void> guardar(Tienda tienda, Cliente cliente) =>
      _base.transaction(() async {
        final existe =
            await (_base.select(
              _base.clientes,
            )..where((c) => c.id.equals(cliente.getId()))).getSingleOrNull() !=
            null;
        await _base
            .into(_base.clientes)
            .insertOnConflictUpdate(
              ClientesCompanion.insert(
                id: cliente.getId(),
                tiendaId: tienda.getId(),
                nombre: cliente.getNombre(),
                nombreNormalizado: normalizarTexto(cliente.getNombre()),
                telefono: Value(cliente.getTelefono()),
                actualizadoEn: DateTime.now().toUtc(),
              ),
            );
        await anotarEnCola(
          _base,
          tiendaId: tienda.getId(),
          tabla: _tabla,
          registroId: cliente.getId(),
          operacion: existe ? OperacionCola.actualizar : OperacionCola.insertar,
        );
      });

  /// Anonimiza al cliente (CUS-21, RNF-16, DI-31): la fila se queda porque
  /// sus fiados, abonos y ventas la referencian (RNF-15), pero no guarda
  /// ningún dato personal. Nombre = 'Cliente eliminado'; `nombre_normalizado`
  /// y `telefono` quedan vacíos. Se anota en `cola_pendientes` como
  /// ACTUALIZAR en la misma transacción (DA-33), porque la fila no se borra.
  @override
  Future<void> eliminar(Tienda tienda, Cliente cliente) =>
      _base.transaction(() async {
        final ahora = DateTime.now().toUtc();
        final filas =
            await (_base.update(_base.clientes)..where(
                  (c) =>
                      c.id.equals(cliente.getId()) &
                      c.tiendaId.equals(tienda.getId()),
                ))
                .write(
                  ClientesCompanion(
                    nombre: const Value(nombreClienteEliminado),
                    nombreNormalizado: const Value(''),
                    telefono: const Value(''),
                    actualizadoEn: Value(ahora),
                    eliminadoEn: Value(ahora),
                  ),
                );
        if (filas == 0) return;
        await anotarEnCola(
          _base,
          tiendaId: tienda.getId(),
          tabla: _tabla,
          registroId: cliente.getId(),
          operacion: OperacionCola.actualizar,
        );
      });

  /// Nombre que queda en la fila de un cliente eliminado (DI-31).
  static const nombreClienteEliminado = 'Cliente eliminado';

  static String _escaparLike(String texto) =>
      texto.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
}
