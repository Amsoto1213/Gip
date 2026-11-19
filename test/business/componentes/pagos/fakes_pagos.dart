import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/abono.dart';
import 'package:gip/business/entidades/pagos/anulacion_venta.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/interfaces/pagos/i_cliente_repositorio.dart';
import 'package:gip/business/interfaces/pagos/i_fiado_repositorio.dart';
import 'package:gip/business/interfaces/pagos/i_venta_repositorio.dart';
import 'package:gip/transversal/texto/normalizar_texto.dart';

import '../gestion_inventario/fakes_catalogo.dart';

/// Ventas en memoria, por tienda y en orden de llegada.
class VentaRepositorioFalso implements IVentaRepositorio, Restaurable {
  final Map<String, List<Venta>> datos = {};
  Map<String, List<Venta>> _copia = {};

  final List<bool> guardadosEnTransaccion = [];
  UnidadTrabajoFalsa? unidad;

  /// Anulaciones guardadas con registrarAnulacion, en orden de llegada.
  final List<AnulacionVenta> anulaciones = [];

  /// Si es verdadero, registrarAnulacion falla (para probar el rollback).
  bool fallarAnulacion = false;

  List<Venta> de(Tienda t) => datos.putIfAbsent(t.getId(), () => []);

  @override
  void tomarCopia() =>
      _copia = {for (final e in datos.entries) e.key: List.of(e.value)};

  @override
  void restaurar() => datos
    ..clear()
    ..addAll(_copia);

  @override
  Future<void> guardar(Tienda tienda, Venta venta) async {
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    de(tienda).add(venta);
  }

  @override
  Future<void> registrarAnulacion(
    Tienda tienda,
    Venta venta,
    AnulacionVenta anulacion,
  ) async {
    if (fallarAnulacion) throw StateError('falla del disco');
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    anulaciones.add(anulacion);
  }

  @override
  Future<List<Venta>> listarPorPeriodo(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async => de(tienda)
      .where(
        (v) => !v.getFecha().isBefore(desde) && v.getFecha().isBefore(hasta),
      )
      .toList();
}

/// Clientes en memoria, por tienda. Busca como la base: contiene el texto,
/// sin mayúsculas ni tildes.
class ClienteRepositorioFalso implements IClienteRepositorio {
  final Map<String, List<Cliente>> datos = {};

  List<Cliente> de(Tienda t) => datos.putIfAbsent(t.getId(), () => []);

  @override
  Future<List<Cliente>> buscarPorNombre(Tienda tienda, String texto) async {
    final buscado = normalizarTexto(texto);
    return de(tienda)
        .where((c) => normalizarTexto(c.getNombre()).contains(buscado))
        .toList();
  }

  @override
  Future<void> guardar(Tienda tienda, Cliente cliente) async {
    de(tienda)
      ..removeWhere((c) => c.getId() == cliente.getId())
      ..add(cliente);
  }

  /// Ids de los clientes que se eliminaron con [eliminar].
  final List<String> eliminados = [];

  @override
  Future<void> eliminar(Tienda tienda, Cliente cliente) async {
    de(tienda).removeWhere((c) => c.getId() == cliente.getId());
    eliminados.add(cliente.getId());
  }
}

/// Fiados en memoria, por tienda. [fallar] simula una falla del disco.
class FiadoRepositorioFalso implements IFiadoRepositorio, Restaurable {
  final Map<String, List<Fiado>> datos = {};
  Map<String, List<Fiado>> _copia = {};

  /// Abonos guardados con registrarAbono, en orden de llegada.
  final List<Abono> abonos = [];
  List<Abono> _copiaAbonos = [];

  final List<bool> guardadosEnTransaccion = [];
  UnidadTrabajoFalsa? unidad;
  bool fallar = false;

  List<Fiado> de(Tienda t) => datos.putIfAbsent(t.getId(), () => []);

  @override
  void tomarCopia() {
    _copia = {for (final e in datos.entries) e.key: List.of(e.value)};
    _copiaAbonos = List.of(abonos);
  }

  @override
  void restaurar() {
    datos
      ..clear()
      ..addAll(_copia);
    abonos
      ..clear()
      ..addAll(_copiaAbonos);
  }

  @override
  Future<void> registrarAbono(Tienda tienda, Fiado fiado, Abono abono) async {
    if (fallar) throw StateError('falla del disco');
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    abonos.add(abono);
  }

  @override
  Future<void> crear(Tienda tienda, Fiado fiado) async {
    if (fallar) throw StateError('falla del disco');
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    de(tienda).add(fiado);
  }

  /// Fiados guardados con actualizarSaldo, en orden de llegada.
  final List<Fiado> actualizados = [];

  @override
  Future<void> actualizarSaldo(Tienda tienda, Fiado fiado) async {
    if (fallar) throw StateError('falla del disco');
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    actualizados.add(fiado);
  }

  /// Fiado de la tienda con ese id (CUS-22).
  @override
  Future<Fiado?> buscarPorId(Tienda tienda, String id) async =>
      de(tienda).where((f) => f.getId() == id).firstOrNull;

  /// Abonos anulados con anularAbono, en orden de llegada.
  final List<Abono> abonosAnulados = [];

  @override
  Future<void> anularAbono(Tienda tienda, Fiado fiado, Abono abono) async {
    if (fallar) throw StateError('falla del disco');
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    abonosAnulados.add(abono);
  }

  /// Fiados de la tienda, del más reciente al más antiguo (CUS-16).
  @override
  Future<List<Fiado>> listar(Tienda tienda) async =>
      List.of(de(tienda))
        ..sort((a, b) => b.getFechaInicio().compareTo(a.getFechaInicio()));

  /// Los abonos no guardan su tienda: se filtran solo por fecha.
  @override
  Future<List<Abono>> listarAbonos(
    Tienda tienda,
    DateTime desde,
    DateTime hasta,
  ) async => abonos
      .where(
        (a) => !a.getFecha().isBefore(desde) && a.getFecha().isBefore(hasta),
      )
      .toList();
}
