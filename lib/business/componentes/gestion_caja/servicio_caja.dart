import 'package:decimal/decimal.dart';
import 'package:gip/business/entidades/gestion_caja/caja.dart';
import 'package:gip/business/entidades/gestion_caja/clasificacion_movimiento.dart';
import 'package:gip/business/entidades/gestion_caja/movimiento_caja.dart';
import 'package:gip/business/entidades/gestion_caja/tipo_movimiento_caja.dart';
import 'package:gip/business/entidades/info_tienda/tienda.dart';
import 'package:gip/business/interfaces/gestion_caja/i_caja_repositorio.dart';
import 'package:gip/transversal/errores/errores_caja.dart';
import 'package:uuid/uuid.dart';

/// Pure Fabrication de la caja: abre la caja del día y crea los movimientos;
/// las cuentas las hace [Caja] (Information Expert) (RF-10).
///
/// Por ahora solo el ingreso de una venta de contado (CUS-02): el movimiento
/// manual, el saldo y el cierre llegan con CUS-11 y CUS-14 (DI-21).
class ServicioCaja {
  ServicioCaja(this._cajas);

  final ICajaRepositorio _cajas;

  /// Id de la caja del día: tienda y fecha local "AAAA-MM-DD" (DA-62, DI-21).
  static String idCaja(Tienda tienda, DateTime dia) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${tienda.getId()}_${dia.year}-${dos(dia.month)}-${dos(dia.day)}';
  }

  /// Día local de [momento], sin hora (DI-21).
  static DateTime diaLocal(DateTime momento) {
    final local = momento.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Creator: busca la caja del día; si no existe, la crea con id = tienda +
  /// fecha y la guarda con cajas.crear.
  Future<Caja> _obtenerCajaDelDia(Tienda tienda, DateTime fecha) async {
    final dia = diaLocal(fecha);
    final existente = await _cajas.buscarPorFecha(tienda, dia);
    if (existente != null) return existente;
    final caja = Caja(idCaja(tienda, dia), dia);
    await _cajas.crear(tienda, caja);
    return caja;
  }

  /// Valida valor > 0, obtiene la caja de hoy, crea el [MovimientoCaja], lo
  /// agrega a la caja (rechaza si está cerrada) y lo guarda (RF-10).
  Future<MovimientoCaja> registrarMovimiento(
    Tienda tienda,
    TipoMovimientoCaja tipo,
    ClasificacionMovimiento clasificacion,
    Decimal valor,
    String descripcion,
  ) async {
    if (valor <= Decimal.zero) throw const ExcepcionValorMovimientoNoValido();
    final ahora = DateTime.now();
    final caja = await _obtenerCajaDelDia(tienda, ahora);
    final movimiento = caja.registrarMovimiento(
      MovimientoCaja(
        const Uuid().v4(),
        valor,
        descripcion,
        clasificacion,
        tipo,
        ahora.toUtc(),
      ),
    );
    await _cajas.registrarMovimiento(tienda, caja, movimiento);
    return movimiento;
  }

  /// Ingreso del NEGOCIO: venta de contado (y, más adelante, abonos en
  /// efectivo).
  Future<MovimientoCaja> registrarIngreso(
    Tienda tienda,
    Decimal valor,
    String descripcion,
  ) => registrarMovimiento(
    tienda,
    TipoMovimientoCaja.ingreso,
    ClasificacionMovimiento.negocio,
    valor,
    descripcion,
  );
}
