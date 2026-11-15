import 'package:gip/business/entidades/info_tienda/tienda.dart';
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
}

/// Fiados en memoria, por tienda. [fallar] simula una falla del disco.
class FiadoRepositorioFalso implements IFiadoRepositorio, Restaurable {
  final Map<String, List<Fiado>> datos = {};
  Map<String, List<Fiado>> _copia = {};

  final List<bool> guardadosEnTransaccion = [];
  UnidadTrabajoFalsa? unidad;
  bool fallar = false;

  List<Fiado> de(Tienda t) => datos.putIfAbsent(t.getId(), () => []);

  @override
  void tomarCopia() =>
      _copia = {for (final e in datos.entries) e.key: List.of(e.value)};

  @override
  void restaurar() => datos
    ..clear()
    ..addAll(_copia);

  @override
  Future<void> crear(Tienda tienda, Fiado fiado) async {
    if (fallar) throw StateError('falla del disco');
    guardadosEnTransaccion.add(unidad?.abierta ?? false);
    de(tienda).add(fiado);
  }
}
