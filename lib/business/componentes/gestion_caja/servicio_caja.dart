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
/// Tiene el ingreso de una venta de contado (CUS-02), el movimiento manual del
/// propietario (CUS-11) y el saldo esperado y el cierre (CUS-14).
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
  /// fecha y la base de apertura de [_calcularBase], y la guarda con
  /// cajas.crear.
  Future<Caja> _obtenerCajaDelDia(Tienda tienda, DateTime fecha) async {
    final dia = diaLocal(fecha);
    final existente = await _cajas.buscarPorFecha(tienda, dia);
    if (existente != null) return existente;
    final caja = Caja(
      idCaja(tienda, dia),
      dia,
      baseApertura: await _calcularBase(tienda, dia),
    );
    await _cajas.crear(tienda, caja);
    return caja;
  }

  /// Efectivo con el que abre la caja de [dia] (DI-38): lo que se contó al
  /// cerrar la caja anterior; si esa no se cerró, su saldo esperado (que ya
  /// incluye su propia base); y cero si es la primera caja de la tienda. Los
  /// retiros se anotan como movimientos, así que la cuenta es continua.
  Future<Decimal> _calcularBase(Tienda tienda, DateTime dia) async {
    final anterior = await _cajas.buscarUltimaAnterior(tienda, dia);
    if (anterior == null) return Decimal.zero;
    return anterior.getEfectivoContado() ?? anterior.calcularSaldoEsperado();
  }

  /// La caja de hoy con sus movimientos y su base de apertura; la abre si no
  /// existe (CUS-11 y CUS-14, DI-38). Para mostrar la lista y las cifras.
  Future<Caja> consultarCajaDelDia(Tienda tienda) =>
      _obtenerCajaDelDia(tienda, DateTime.now());

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

  /// Movimiento que anota el propietario (CUS-11, RF-10): rechaza la
  /// clasificación ANULACION, que solo usa la anulación de ventas, y llama a
  /// [registrarMovimiento].
  Future<MovimientoCaja> registrarMovimientoManual(
    Tienda tienda,
    TipoMovimientoCaja tipo,
    ClasificacionMovimiento clasificacion,
    Decimal valor,
    String descripcion,
  ) async {
    if (clasificacion == ClasificacionMovimiento.anulacion) {
      throw const ExcepcionClasificacionNoPermitida();
    }
    return registrarMovimiento(tienda, tipo, clasificacion, valor, descripcion);
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

  /// Obtiene la caja de hoy con [_obtenerCajaDelDia] (la abre si no existe) y
  /// devuelve su saldo esperado (CUS-14, pasos 5 a 9). No se guarda: se
  /// calcula de los movimientos (DA-62).
  Future<Decimal> consultarSaldoEsperado(Tienda tienda) async {
    final caja = await _obtenerCajaDelDia(tienda, DateTime.now());
    return caja.calcularSaldoEsperado();
  }

  /// Obtiene la caja de hoy, la cierra con [efectivoContado] (rechaza si ya
  /// está cerrada), guarda solo el cierre y devuelve el faltante (negativo) o
  /// el sobrante (positivo) (CUS-14, pasos 16 a 26; RF-13).
  Future<Decimal> cerrarCaja(Tienda tienda, Decimal efectivoContado) async {
    final caja = await _obtenerCajaDelDia(tienda, DateTime.now());
    final diferencia = caja.cerrar(efectivoContado);
    await _cajas.cerrar(tienda, caja);
    return diferencia;
  }
}
