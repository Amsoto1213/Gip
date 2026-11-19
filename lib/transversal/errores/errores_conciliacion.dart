import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Errores de la revisión de conflictos de sincronización (CUS-22).

/// La decisión ya se aplicó: aplicarla otra vez, por ejemplo la devolución de
/// un abono, la repetiría (DI-45).
class ExcepcionConflictoYaResuelto extends ExcepcionNegocio {
  const ExcepcionConflictoYaResuelto()
    : super('Este conflicto ya estaba resuelto');
}

/// Ningún resolutor atiende ese tipo de conflicto (CUS-22, paso 18).
class ExcepcionConflictoSinResolutor extends ExcepcionNegocio {
  const ExcepcionConflictoSinResolutor()
    : super('No se sabe cómo resolver este tipo de conflicto');
}

/// No aparecen los registros del conflicto (por ejemplo, ya se corrigieron en
/// otro equipo).
class ExcepcionRegistrosDelConflictoNoEncontrados extends ExcepcionNegocio {
  const ExcepcionRegistrosDelConflictoNoEncontrados()
    : super(
        'No se encontraron los registros de este conflicto. Actualice la '
        'pantalla',
      );
}

/// La decisión no marca nada y el tipo de conflicto la necesita (DI-45).
class ExcepcionDecisionIncompleta extends ExcepcionNegocio {
  const ExcepcionDecisionIncompleta(super.mensaje);
}

/// Con los abonos elegidos, el fiado todavía queda con saldo negativo (DI-45).
class ExcepcionAbonoSigueExcedido extends ExcepcionNegocio {
  const ExcepcionAbonoSigueExcedido()
    : super(
        'Con esos abonos el fiado todavía queda con saldo negativo. Marque '
        'más abonos',
      );
}
