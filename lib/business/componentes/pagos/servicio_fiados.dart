import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/interfaces/pagos/i_fiado_repositorio.dart';
import 'package:gip/transversal/errores/errores_pagos.dart';
import 'package:uuid/uuid.dart';

/// Pure Fabrication y Creator del fiado como forma de pago (CUR-07, RF-07): lo
/// crea en memoria y lo guarda cuando se confirma la venta. No depende de la
/// caja ni de los clientes (DA-69).
///
/// Anula un fiado con [anularFiado] (CUS-20). `listarFiados` y
/// `buscarFiadosPorCliente` llegan con CUS-19 (DI-26).
class ServicioFiados {
  ServicioFiados(this._fiados);

  final IFiadoRepositorio _fiados;

  /// Creator: valida monto > 0 (IE-06) y crea el [Fiado] con id nuevo, el
  /// monto como saldo y estado PENDIENTE. Queda en memoria hasta que se
  /// confirma la venta.
  Fiado crearFiado(Cliente cliente, Decimal monto) {
    if (monto <= Decimal.zero) throw const ExcepcionMontoFiadoNoValido();
    return Fiado(const Uuid().v4(), monto, DateTime.now().toUtc(), cliente);
  }

  /// Agrega el fiado a su cliente y lo inserta con fiados.crear. Lo invoca
  /// ProcesadorFiado dentro de la transacción de ServicioVentas.confirmar
  /// (RNF-04).
  Future<void> registrarFiado(Tienda tienda, Fiado fiado) async {
    fiado.getCliente().agregarFiado(fiado);
    await _fiados.crear(tienda, fiado);
  }

  /// Llama a fiado.anular() (rechaza si ya tiene abonos) y guarda con
  /// fiados.actualizarSaldo. Lo invoca ProcesadorFiado.revertir dentro de la
  /// transacción de ServicioVentas.anular (CUS-20). Si el guardado falla, el
  /// fiado conserva su saldo y su estado anteriores.
  Future<void> anularFiado(Tienda tienda, Fiado fiado) async {
    final saldoAnterior = fiado.getSaldoPendiente();
    final estadoAnterior = fiado.getEstado();
    fiado.anular();
    try {
      await _fiados.actualizarSaldo(tienda, fiado);
    } catch (_) {
      fiado.restaurar(saldoAnterior, estadoAnterior);
      rethrow;
    }
  }
}
