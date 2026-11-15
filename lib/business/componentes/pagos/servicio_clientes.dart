import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/interfaces/pagos/i_cliente_repositorio.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';
import 'package:uuid/uuid.dart';

/// Pure Fabrication de los clientes del fiado (RNF-16): los busca y los
/// registra; el saldo lo calcula [Cliente] (Information Expert, DA-69).
///
/// `obtenerHistorial` llega con CUS-19 completo (DI-26, DI-27).
class ServicioClientes {
  ServicioClientes(this._clientes);

  final IClienteRepositorio _clientes;

  /// Llama a clientes.buscarPorNombre(tienda, nombre).
  Future<List<Cliente>> buscarClientes(Tienda tienda, String nombre) =>
      _clientes.buscarPorNombre(tienda, nombre);

  /// Llama a cliente.calcularSaldoPendiente() (CUS-19).
  Decimal consultarSaldoTotal(Cliente cliente) =>
      cliente.calcularSaldoPendiente();

  /// Elimina los datos del cliente a solicitud del titular (CUS-21, RNF-16):
  /// rechaza con [ExcepcionClienteConSaldo] si cliente.puedeEliminarse() es
  /// falso y, si no, llama a clientes.eliminar(tienda, cliente). La
  /// confirmación la pide la pantalla (RNF-26).
  Future<void> eliminarCliente(Tienda tienda, Cliente cliente) async {
    if (!cliente.puedeEliminarse()) throw const ExcepcionClienteConSaldo();
    await _clientes.eliminar(tienda, cliente);
  }

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
