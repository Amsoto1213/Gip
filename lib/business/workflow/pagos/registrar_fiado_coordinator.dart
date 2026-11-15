import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/pagos/servicio_clientes.dart';
import 'package:gip/business/componentes/pagos/servicio_fiados.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';

/// Controller del caso de uso CUS-07 Registrar fiado (extiende CUS-02): busca
/// y registra al cliente ([ServicioClientes]) y prepara el fiado
/// ([ServicioFiados]). El fiado queda en memoria; la pantalla lo entrega en
/// RegistrarVentaCoordinator.confirmarVenta, donde se guarda.
class RegistrarFiadoCoordinator {
  RegistrarFiadoCoordinator(this._servicioClientes, this._servicioFiados);

  final ServicioClientes _servicioClientes;
  final ServicioFiados _servicioFiados;

  /// Llama a servicioClientes.buscarClientes(tienda, nombre). No está en EA:
  /// en el diseño lo da ConsultarClienteCoordinator (CUS-19); está aquí para
  /// que la pantalla use un solo coordinador (DI-26).
  Future<List<Cliente>> buscarClientes(Tienda tienda, String nombre) =>
      _servicioClientes.buscarClientes(tienda, nombre);

  /// Extensión: el cliente no está registrado. Lo guarda de una vez.
  Future<Cliente> registrarCliente(
    Tienda tienda,
    String nombre,
    String telefono,
  ) => _servicioClientes.registrarCliente(tienda, nombre, telefono);

  /// Llama a servicioFiados.crearFiado(cliente, monto).
  Fiado prepararFiado(Cliente cliente, Decimal monto) =>
      _servicioFiados.crearFiado(cliente, monto);
}
