import 'dart:async';

import 'package:gip/business/interfaces/i_unidad_trabajo.dart';
import 'package:gip/data/local/base_local_drift.dart';

/// [IUnidadTrabajo] con una transacción de drift (RNF-04, DA-44).
class UnidadTrabajoDrift implements IUnidadTrabajo {
  UnidadTrabajoDrift(this._base);

  final BaseLocalDrift _base;

  /// Marca la zona de una ejecución abierta por esta unidad de trabajo.
  final _clave = Object();

  /// Una llamada anidada corre dentro de la transacción de afuera, sin abrir
  /// un savepoint: si la acción de adentro falla y el error sube, se deshace
  /// todo (DA-53).
  @override
  Future<void> ejecutar(Future<void> Function() accion) {
    if (Zone.current[_clave] == true) return accion();
    return _base.transaction(
      () => runZoned(accion, zoneValues: {_clave: true}),
    );
  }
}
