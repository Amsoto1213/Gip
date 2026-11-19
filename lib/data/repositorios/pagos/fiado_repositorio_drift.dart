import 'package:drift/drift.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/interfaces/pagos/i_fiado_repositorio.dart';
import 'package:gip/data/helpers/cola_sincronizacion.dart';
import 'package:gip/data/local/base_local_drift.dart';
import 'package:gip/data/repositorios/pagos/mapeo_fiado.dart';

/// [IFiadoRepositorio] sobre la base local (drift).
class FiadoRepositorioDrift implements IFiadoRepositorio {
  FiadoRepositorioDrift(this._base);

  final BaseLocalDrift _base;

  static const _tabla = 'fiados';

  /// Inserta el fiado (su fila FIADO de `formas_pago` ya la guardó la venta,
  /// con el mismo id) y lo anota en `cola_pendientes`. Se une a la transacción
  /// de la venta: si algo falla, no queda nada (RNF-04, DA-33).
  @override
  Future<void> crear(Tienda tienda, Fiado fiado) => _base.transaction(() async {
    await _base
        .into(_base.fiados)
        .insert(
          FiadosCompanion.insert(
            id: fiado.getId(),
            tiendaId: tienda.getId(),
            clienteId: fiado.getCliente().getId(),
            montoInicial: fiado.getMontoInicial(),
            saldoPendiente: fiado.getSaldoPendiente(),
            estado: MapeoFiado.estadoATexto(fiado.getEstado()),
            fechaInicio: fiado.getFechaInicio(),
          ),
        );
    await anotarEnCola(
      _base,
      tiendaId: tienda.getId(),
      tabla: _tabla,
      registroId: fiado.getId(),
      operacion: OperacionCola.insertar,
    );
  });

  /// En una transacción inserta solo el abono nuevo, actualiza solo el saldo y
  /// el estado del fiado (que [Fiado.registrarAbono] ya recalculó) y anota las
  /// dos escrituras en `cola_pendientes` (RNF-04, DA-33, DA-46). Se une a la
  /// transacción de ServicioAbonos: si la caja falla, no queda nada.
  @override
  Future<void> registrarAbono(Tienda tienda, Fiado fiado, Abono abono) =>
      _base.transaction(() async {
        await _base
            .into(_base.abonos)
            .insert(
              AbonosCompanion.insert(
                id: abono.getId(),
                tiendaId: tienda.getId(),
                fiadoId: fiado.getId(),
                monto: abono.getMonto(),
                fecha: abono.getFecha(),
                medio: MapeoFiado.medioATexto(abono.getMedio()),
                referencia: Value(abono.getReferencia()),
                anulado: Value(abono.isAnulado()),
              ),
            );
        await anotarEnCola(
          _base,
          tiendaId: tienda.getId(),
          tabla: 'abonos',
          registroId: abono.getId(),
          operacion: OperacionCola.insertar,
        );
        await (_base.update(_base.fiados)..where(
              (f) =>
                  f.id.equals(fiado.getId()) &
                  f.tiendaId.equals(tienda.getId()),
            ))
            .write(
              FiadosCompanion(
                saldoPendiente: Value(fiado.getSaldoPendiente()),
                estado: Value(MapeoFiado.estadoATexto(fiado.getEstado())),
              ),
            );
        await anotarEnCola(
          _base,
          tiendaId: tienda.getId(),
          tabla: _tabla,
          registroId: fiado.getId(),
          operacion: OperacionCola.actualizar,
        );
      });

  /// Guarda solo el saldo y el estado del fiado y lo anota en `cola_pendientes`
  /// como ACTUALIZAR en la misma transacción (DA-33); no toca los abonos
  /// (CUS-20). Se une a la transacción abierta.
  @override
  Future<void> actualizarSaldo(Tienda tienda, Fiado fiado) => _base.transaction(
    () async {
      await (_base.update(_base.fiados)..where(
            (f) =>
                f.id.equals(fiado.getId()) & f.tiendaId.equals(tienda.getId()),
          ))
          .write(
            FiadosCompanion(
              saldoPendiente: Value(fiado.getSaldoPendiente()),
              estado: Value(MapeoFiado.estadoATexto(fiado.getEstado())),
            ),
          );
      await anotarEnCola(
        _base,
        tiendaId: tienda.getId(),
        tabla: _tabla,
        registroId: fiado.getId(),
        operacion: OperacionCola.actualizar,
      );
    },
  );

  /// Abonos de la tienda con fecha en `[desde, hasta)`, con los anulados
  /// (CUS-10, DI-29). Toda consulta filtra por `tienda_id`.
  @override
  Future<List<Abono>> listarAbonos(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async {
    final filas =
        await (_base.select(_base.abonos)
              ..where(
                (a) =>
                    a.tiendaId.equals(tienda.getId()) &
                    a.fecha.isBiggerOrEqualValue(desde.toUtc()) &
                    a.fecha.isSmallerThanValue(hasta.toUtc()),
              )
              ..orderBy([(a) => OrderingTerm.asc(a.fecha)]))
            .get();
    return filas.map(MapeoFiado.abonoAEntidad).toList();
  }

  /// Todos los fiados de la tienda (también los saldados y los anulados), del
  /// más reciente al más antiguo, cada uno con su cliente y sus abonos, del más
  /// antiguo al más reciente (CUS-16, DI-41). Toda consulta filtra por
  /// `tienda_id`.
  @override
  Future<List<Fiado>> listar(Tienda tienda) async {
    final filas =
        await (_base.select(_base.fiados)
              ..where((f) => f.tiendaId.equals(tienda.getId()))
              ..orderBy([(f) => OrderingTerm.desc(f.fechaInicio)]))
            .get();
    if (filas.isEmpty) return const [];

    final clientes = {
      for (final c in await (_base.select(
        _base.clientes,
      )..where((c) => c.tiendaId.equals(tienda.getId()))).get())
        c.id: Cliente(c.id, c.nombre, c.telefono),
    };
    final abonos =
        await (_base.select(_base.abonos)
              ..where((a) => a.tiendaId.equals(tienda.getId()))
              ..orderBy([(a) => OrderingTerm.asc(a.fecha)]))
            .get();
    final porFiado = <String, List<FilaAbono>>{};
    for (final a in abonos) {
      porFiado.putIfAbsent(a.fiadoId, () => []).add(a);
    }
    return [
      for (final fila in filas)
        MapeoFiado.aEntidad(
          fila,
          clientes[fila.clienteId] ?? Cliente(fila.clienteId, '', ''),
          porFiado[fila.id] ?? const [],
        ),
    ];
  }

  /// Fiado de la tienda con su cliente y todos sus abonos, del más antiguo al
  /// más reciente y con los anulados (CUS-22, DI-45). Filtra por `tienda_id`.
  @override
  Future<Fiado?> buscarPorId(Tienda tienda, String id) async {
    final fila =
        await (_base.select(_base.fiados)..where(
              (f) => f.tiendaId.equals(tienda.getId()) & f.id.equals(id),
            ))
            .getSingleOrNull();
    if (fila == null) return null;
    final c =
        await (_base.select(_base.clientes)..where(
              (c) =>
                  c.tiendaId.equals(tienda.getId()) &
                  c.id.equals(fila.clienteId),
            ))
            .getSingleOrNull();
    final abonos =
        await (_base.select(_base.abonos)
              ..where(
                (a) => a.tiendaId.equals(tienda.getId()) & a.fiadoId.equals(id),
              )
              ..orderBy([(a) => OrderingTerm.asc(a.fecha)]))
            .get();
    return MapeoFiado.aEntidad(
      fila,
      c == null
          ? Cliente(fila.clienteId, '', '')
          : Cliente(c.id, c.nombre, c.telefono),
      abonos,
    );
  }

  /// Guarda solo que el abono quedó anulado y lo anota en `cola_pendientes`
  /// como ACTUALIZAR en la misma transacción (DA-33, RNF-15). No toca el saldo
  /// del fiado ni los demás abonos. Se une a la transacción abierta.
  @override
  Future<void> anularAbono(Tienda tienda, Fiado fiado, Abono abono) =>
      _base.transaction(() async {
        await (_base.update(_base.abonos)..where(
              (a) =>
                  a.id.equals(abono.getId()) &
                  a.tiendaId.equals(tienda.getId()),
            ))
            .write(const AbonosCompanion(anulado: Value(true)));
        await anotarEnCola(
          _base,
          tiendaId: tienda.getId(),
          tabla: 'abonos',
          registroId: abono.getId(),
          operacion: OperacionCola.actualizar,
        );
      });
}
