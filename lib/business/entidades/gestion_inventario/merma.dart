import 'package:gip/business/entidades/gestion_inventario/motivo_merma.dart';
import 'package:gip/business/entidades/gestion_inventario/movimiento_inventario.dart';

/// Mercancía retirada por vencimiento, daño o devolución, con su motivo
/// (RF-03). La cantidad se guarda negativa: resta del stock (DA-19).
class Merma extends MovimientoInventario {
  Merma(super.id, super.item, super.cantidad, super.fecha, this._motivo);

  final MotivoMerma _motivo;

  MotivoMerma getMotivo() => _motivo;
}
