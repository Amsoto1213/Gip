import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/pagos/servicio_clientes.dart';
import 'package:gip/business/componentes/pagos/servicio_fiados.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';

/// Controller del caso de uso CUS-19 Consultar saldo e historial de cliente;
/// lo usan también las pantallas de CUS-07 y CUS-08 («include»).
///
/// Por ahora solo [buscarClientes] y [consultarSaldoTotal]. `listarFiados`,
/// `buscarFiadosPorCliente`, `consultarHistorial` y `eliminarCliente` llegan
/// con CUS-19 completo y CUS-21 (DI-27). Recibe [ServicioFiados] como en EA,
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
}
