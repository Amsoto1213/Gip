import 'package:gip/business/entidades/info_tienda/tienda.dart';

/// Protected Variations: la Business Layer pregunta si quedan datos sin enviar
/// al servidor sin conocer al Sincronizador de la Data Layer, que lo implementa
/// (ERS 3.2.5 c, DA-62).
abstract interface class IEstadoSincronizacion {
  /// Verdadero si hay operaciones de la tienda guardadas en el dispositivo que
  /// aún no se han enviado al servidor (ERS 3.2.5 c). Es `Future<bool>` y no
  /// `bool` como en EA, porque consultar la base local es asíncrono (DI-29).
  Future<bool> hayPendientes(Tienda tienda);
}
