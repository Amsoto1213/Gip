import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/interfaces/pagos/i_cliente_repositorio.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';
import 'package:uuid/uuid.dart';

/// Pure Fabrication de los clientes del fiado (RNF-16): los busca y los
/// registra; el saldo lo calcula [Cliente] (Information Expert, DA-69).
///
/// `consultarSaldoTotal`, `obtenerHistorial` y `eliminarCliente` llegan con
/// CUS-19 y CUS-21 (DI-26).
class ServicioClientes {
  ServicioClientes(this._clientes);

  final IClienteRepositorio _clientes;

  /// Llama a clientes.buscarPorNombre(tienda, nombre).
  Future<List<Cliente>> buscarClientes(Tienda tienda, String nombre) =>
      _clientes.buscarPorNombre(tienda, nombre);

  /// Creator: valida que el nombre no esté vacío, crea el [Cliente] con id
  /// nuevo y lo guarda. Nombre y teléfono van sin espacios a los lados; sin
  /// teléfono queda vacío (DI-26).
  Future<Cliente> registrarCliente(
    Tienda tienda,
    String nombre,
    String telefono,
  ) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) throw const ExcepcionNombreClienteObligatorio();
    final cliente = Cliente(const Uuid().v4(), limpio, telefono.trim());
    await _clientes.guardar(tienda, cliente);
    return cliente;
  }
}
