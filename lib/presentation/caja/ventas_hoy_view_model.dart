import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_inventario/estado_movimiento.dart';
import 'package:gip/business/entidades/gestion_inventario/salida_venta.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/entidades/pagos/fiado.dart';
import 'package:gip/business/entidades/pagos/pago_contado.dart';
import 'package:gip/business/entidades/pagos/pago_nequi.dart';
import 'package:gip/business/entidades/pagos/venta.dart';
import 'package:gip/business/workflow/pagos/anular_venta_coordinator.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Periodo de las ventas que se muestran.
enum PeriodoVentas { hoy, ayer, fechas }

/// Lo que pasará al anular una venta, para decírselo al propietario antes de
/// confirmar (CUS-20, paso 12): los productos que vuelven al surtido, el
/// efectivo que sale de la caja de hoy, el fiado que queda anulado y lo que se
/// devuelve por Nequi.
class ResumenAnulacion {
  const ResumenAnulacion({
    required this.productos,
    required this.salenDeCaja,
    required this.fiadoAnulado,
    required this.devolverPorNequi,
  });

  final int productos;
  final Decimal salenDeCaja;
  final Decimal fiadoAnulado;
  final Decimal devolverPorNequi;
}

/// Estado de la pantalla Ventas de hoy (CUS-20, DI-39). Llama solo a
/// [AnularVentaCoordinator]. Una venta anulada queda en la lista, marcada;
/// nunca se borra (RNF-15).
class VentasHoyViewModel extends ChangeNotifier {
  VentasHoyViewModel(
    this._coordinador,
    this._usuarioActivo, {
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  static const _mensajeFalla =
      'No se pudo cargar las ventas. Inténtalo de nuevo';
  static const _mensajeFallaAnular =
      'No se pudo anular la venta. Inténtalo de nuevo';

  /// Mensaje del diagrama al anular (CUS-20, paso 34).
  static const avisoAnulada = 'Venta anulada';

  final AnularVentaCoordinator _coordinador;
  final UsuarioActivo _usuarioActivo;
  final DateTime Function() _reloj;

  PeriodoVentas _periodo = PeriodoVentas.hoy;
  DateTime? _desde;
  DateTime? _hasta;
  List<Venta> _ventas = const [];
  Map<String, List<SalidaVenta>> _salidas = const {};
  bool _cargando = false;
  bool _anulando = false;
  String? _error;
  String? _aviso;
  int _consulta = 0;

  PeriodoVentas get periodo => _periodo;

  /// Primer día del periodo (hora 00:00 local).
  DateTime get desde => _desde ?? _hoy();

  /// Último día del periodo (hora 00:00 local; ese día entra completo).
  DateTime get hasta => _hasta ?? _hoy();

  bool get cargando => _cargando;
  bool get anulando => _anulando;

  /// Mensaje de error para el tendero, o null.
  String? get error => _error;

  /// "Venta anulada", o null.
  String? get aviso => _aviso;

  /// Ventas del periodo, la más reciente primero.
  List<Venta> get ventas => _ventas;

  DateTime _hoy() {
    final ahora = _reloj();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  /// Nombres de los productos de la venta, en el orden en que se vendieron.
  List<String> nombresDe(Venta venta) => [
    for (final s in _salidas[venta.getId()] ?? const <SalidaVenta>[])
      s.getItem().getProducto().getNombre(),
  ];

  /// "Efectivo", "Nequi", "Fiado" o varias juntas ("Efectivo + Nequi").
  static String pagoDe(Venta venta) => [
    for (final f in venta.getFormasPago())
      switch (f) {
        PagoContado() => 'Efectivo',
        PagoNequi() => 'Nequi',
        Fiado() => 'Fiado',
        _ => 'Otro',
      },
  ].join(' + ');

  /// Lo que pasará al anular [venta]. Solo las salidas vigentes vuelven al
  /// surtido; el efectivo que sale de la caja es lo que cubrió el pago de
  /// contado (no el cambio).
  ResumenAnulacion resumenDe(Venta venta) {
    var salen = Decimal.zero;
    var fiado = Decimal.zero;
    var nequi = Decimal.zero;
    for (final f in venta.getFormasPago()) {
      final monto = f.calcularMontoCubierto();
      switch (f) {
        case PagoContado():
          salen += monto;
        case PagoNequi():
          nequi += monto;
        case Fiado():
          fiado += monto;
        default:
      }
    }
    final vigentes = (_salidas[venta.getId()] ?? const <SalidaVenta>[]).where(
      (s) => s.getEstado() == EstadoMovimiento.vigente,
    );
    return ResumenAnulacion(
      productos: vigentes.length,
      salenDeCaja: salen,
      fiadoAnulado: fiado,
      devolverPorNequi: nequi,
    );
  }

  /// Elige Hoy o Ayer y carga.
  Future<void> elegirPeriodo(PeriodoVentas periodo) {
    final hoy = _hoy();
    _periodo = periodo;
    switch (periodo) {
      case PeriodoVentas.hoy:
        _desde = hoy;
        _hasta = hoy;
      case PeriodoVentas.ayer:
        final ayer = DateTime(hoy.year, hoy.month, hoy.day - 1);
        _desde = ayer;
        _hasta = ayer;
      case PeriodoVentas.fechas:
        break;
    }
    return cargar();
  }

  /// Elige un rango de fechas (ambos días incluidos) y carga. Un día futuro se
  /// lleva a hoy, y si el rango viene al revés se ordena.
  Future<void> elegirFechas(DateTime desde, DateTime hasta) {
    final hoy = _hoy();
    DateTime dia(DateTime f) {
      final d = DateTime(f.year, f.month, f.day);
      return d.isAfter(hoy) ? hoy : d;
    }

    var a = dia(desde);
    var b = dia(hasta);
    if (b.isBefore(a)) (a, b) = (b, a);
    _periodo = PeriodoVentas.fechas;
    _desde = a;
    _hasta = b;
    return cargar();
  }

  /// Carga las ventas del periodo con sus productos (CUS-20, pasos 1 a 10). Con
  /// [conservarMensajes] deja el aviso y el error que ya hay (al volver a leer
  /// después de anular).
  Future<void> cargar({bool conservarMensajes = false}) async {
    final consulta = ++_consulta;
    _cargando = true;
    if (!conservarMensajes) {
      _error = null;
      _aviso = null;
    }
    notifyListeners();
    final fin = DateTime(hasta.year, hasta.month, hasta.day + 1);
    List<Venta> ventas = const [];
    Map<String, List<SalidaVenta>> salidas = const {};
    String? error;
    try {
      ventas = await _coordinador.listarVentas(
        _usuarioActivo.tienda,
        desde,
        fin,
        _usuarioActivo.usuario,
      );
      salidas = await _coordinador.listarProductos(
        _usuarioActivo.tienda,
        ventas,
        _usuarioActivo.usuario,
      );
    } on ExcepcionNegocio catch (e) {
      error = e.mensaje;
    } catch (_) {
      error = _mensajeFalla;
    }
    if (consulta != _consulta) return;
    _ventas = [...ventas]..sort((a, b) => b.getFecha().compareTo(a.getFecha()));
    _salidas = salidas;
    _error = error ?? (conservarMensajes ? _error : null);
    _cargando = false;
    notifyListeners();
  }

  /// Anula la venta con su [motivo] (CUS-20, pasos 14 a 34). Devuelve
  /// verdadero si quedó anulada. Si falla (caja cerrada, fiado con abonos),
  /// no se guarda nada y se vuelve a leer la lista.
  Future<bool> anular(Venta venta, String motivo) async {
    if (_anulando) return false;
    _anulando = true;
    _error = null;
    _aviso = null;
    notifyListeners();
    var anulada = false;
    try {
      await _coordinador.anularVenta(
        _usuarioActivo.tienda,
        venta,
        motivo,
        _usuarioActivo.usuario,
      );
      _aviso = avisoAnulada;
      anulada = true;
    } on ExcepcionNegocio catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = _mensajeFallaAnular;
    }
    _anulando = false;
    notifyListeners();
    // Se vuelve a leer: tras un fallo, la venta en memoria puede haber quedado
    // a medias.
    await cargar(conservarMensajes: true);
    return anulada;
  }
}
