import 'package:gip/business/entidades/gestion_inventario/alerta_reabastecimiento.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Indirection, Protected Variations y DIP: contrato de acceso a las alertas
/// de reabastecimiento; la Data Layer lo implementa (RNF-08).
abstract interface class IAlertaRepositorio {
  /// Guarda las alertas del día y descarta las anteriores de esa fecha, para
  /// no duplicarlas si se calculan otra vez (RD-11, DA-35).
  Future<void> reemplazar(
    Tienda tienda,
    DateTime fecha,
    List<AlertaReabastecimiento> alertas,
  );

  /// Alertas ya calculadas de esa fecha; lectura rápida del panel (RD-09).
  Future<List<AlertaReabastecimiento>> listarPorFecha(
    Tienda tienda,
    DateTime fecha,
  );
}
