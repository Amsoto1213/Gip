import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/pagos/servicio_clientes.dart';
import 'package:gip/business/componentes/pagos/servicio_fiados.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';

/// Controller del caso de uso CUS-19 Consultar saldo e historial de cliente;
/// lo usan también las pantallas de CUS-07 y CUS-08 («include»).
///
/// Por ahora [buscarClientes], [consultarSaldoTotal] y [eliminarCliente]
/// (CUS-21). `listarFiados`, `buscarFiadosPorCliente` y `consultarHistorial`
/// llegan con CUS-19 completo (DI-27). Recibe [ServicioFiados] como en EA,
/// aunque aún no lo usa.
class ConsultarClienteCoordinator {
  ConsultarClienteCoordinator(
    this._servicioClientes,
    ServicioFiados servicioFiados,
  );

  final ServicioClientes _servicioClientes;

  /// Llama a servicioClientes.buscarClientes(tienda, nombre).
  Future<List<Cliente>> buscarClientes(Tienda tienda, String nombre) =>
      _servicioClientes.buscarClientes(tienda, nombre);

  /// Llama a servicioClientes.consultarSaldoTotal(cliente).
  Decimal consultarSaldoTotal(Cliente cliente) =>
      _servicioClientes.consultarSaldoTotal(cliente);

  /// Llama a servicioClientes.eliminarCliente(tienda, cliente) (CUS-21,
  /// RNF-16). La confirmación explícita la pide la pantalla antes de llamar
  /// (RNF-26).
  Future<void> eliminarCliente(Tienda tienda, Cliente cliente) =>
      _servicioClientes.eliminarCliente(tienda, cliente);
}
