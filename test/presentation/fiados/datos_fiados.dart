import 'package:decimal/decimal.dart';
import 'package:gip/business/componentes/gestion_caja/servicio_caja.dart';
import 'package:gip/business/componentes/pagos/servicio_abonos.dart';
import 'package:gip/business/componentes/pagos/servicio_clientes.dart';
import 'package:gip/business/componentes/pagos/servicio_fiados.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/entidades/pagos/cliente.dart';
import 'package:gip/business/entidades/pagos/estado_fiado.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/workflow/pagos/consultar_cliente_coordinator.dart';
import 'package:gip/business/workflow/pagos/registrar_abono_coordinator.dart';

import '../../business/componentes/gestion_caja/fakes_caja.dart';
import '../../business/componentes/gestion_inventario/fakes_catalogo.dart';
import '../../business/componentes/pagos/fakes_pagos.dart';

Decimal d(String v) => Decimal.parse(v);

final tiendaFiados = Tienda('t1', 'T001', 'Granero El Porvenir', 'Arjona');

/// Coordinadores reales de CUS-19 y CUS-08 sobre repositorios en memoria, con
/// dos clientes que deben (María, con dos fiados, y José, con uno) y uno al
/// día (Luz).
class DatosFiados {
  DatosFiados._(
    this.consultar,
    this.abonar,
    this.clientes,
    this.fiados,
    this.cajas,
    this.maria,
    this.fiadoViejo,
    this.fiadoNuevo,
  );

  final ConsultarClienteCoordinator consultar;
  final RegistrarAbonoCoordinator abonar;
  final ClienteRepositorioFalso clientes;
  final FiadoRepositorioFalso fiados;
  final CajaRepositorioFalso cajas;
  final Cliente maria;
  final Fiado fiadoViejo;
  final Fiado fiadoNuevo;

  static Future<DatosFiados> crear() async {
    final clientes = ClienteRepositorioFalso();
    final fiados = FiadoRepositorioFalso();
    final cajas = CajaRepositorioFalso();
    final unidad = UnidadTrabajoFalsa([fiados, cajas]);
    fiados.unidad = unidad;
    cajas.unidad = unidad;

    final maria = Cliente('c1', 'María Pérez', '300 412 4521');
    final viejo = Fiado.guardado(
      'f1',
      d('25000'),
      DateTime.utc(2026, 10, 28, 15),
      maria,
      d('12500'),
      EstadoFiado.pendiente,
    );
    final nuevo = Fiado.guardado(
      'f2',
      d('15000'),
      DateTime.utc(2026, 11, 9, 15),
      maria,
      d('15000'),
      EstadoFiado.pendiente,
    );
    maria
      ..agregarFiado(nuevo)
      ..agregarFiado(viejo);
    final jose = Cliente('c2', 'José Barrios', '');
    jose.agregarFiado(
      Fiado.guardado(
        'f3',
        d('62000'),
        DateTime.utc(2026, 10, 2, 15),
        jose,
        d('62000'),
        EstadoFiado.pendiente,
      ),
    );
    final luz = Cliente('c3', 'Luz Marina Díaz', '');
    luz.agregarFiado(
      Fiado.guardado(
        'f4',
        d('9000'),
        DateTime.utc(2026, 10, 12, 15),
        luz,
        Decimal.zero,
        EstadoFiado.saldado,
      ),
    );
    for (final c in [maria, jose, luz]) {
      await clientes.guardar(tiendaFiados, c);
    }

    return DatosFiados._(
      ConsultarClienteCoordinator(
        ServicioClientes(clientes),
        ServicioFiados(fiados),
      ),
      RegistrarAbonoCoordinator(
        ServicioAbonos(fiados, ServicioCaja(cajas), unidad),
      ),
      clientes,
      fiados,
      cajas,
      maria,
      viejo,
      nuevo,
    );
  }
}
