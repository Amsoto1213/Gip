import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/gestion_caja/consultar_margen_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Periodos que ofrece la pantalla Ganancia por producto.
enum PeriodoMargen { hoy, semana, mes, fechas }

/// Margen de un producto; [margen] nulo = dato incompleto (falta el costo).
typedef FilaMargen = ({Producto producto, Decimal? margen});

/// Estado de la pantalla Ganancia por producto (CUS-09). Llama solo a
/// [ConsultarMargenCoordinator]. El periodo va de `desde` a `hasta` sin incluir
/// `hasta` (DI-28), en días locales.
class MargenViewModel extends ChangeNotifier {
  MargenViewModel(
    this._coordinador,
    this._usuarioActivo, {
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now {
    _fijarPeriodo();
  }

  /// Mensaje del diagrama cuando no es el propietario (CUS-05, paso 7).
  static const mensajeSoloPropietario =
      'Esta consulta es solo para el propietario';

  static const mensajeSinVentas = 'No hay ventas en este periodo';

  static const _mensajeFalla =
      'No se pudo calcular la ganancia. Intente de nuevo';

  /// La semana son los últimos 7 días, contando hoy (DI-28).
  static const diasSemana = 7;

  final ConsultarMargenCoordinator _coordinador;
  final UsuarioActivo _usuarioActivo;
  final DateTime Function() _reloj;

  bool _cargando = false;
  String? _error;
  PeriodoMargen _periodo = PeriodoMargen.semana;
  DateTime? _desdeElegido;
  DateTime? _hastaElegido;
  late DateTime _desde;
  late DateTime _hasta;
  List<FilaMargen> _filas = const [];

  bool get cargando => _cargando;

  /// Mensaje para el tendero si la consulta no se pudo hacer.
  String? get error => _error;
  PeriodoMargen get periodo => _periodo;

  /// Primer día del periodo mostrado (incluido).
  DateTime get desde => _desde;

  /// Último día del periodo mostrado (incluido).
  DateTime get ultimoDia => DateTime(_hasta.year, _hasta.month, _hasta.day - 1);

  /// Productos con ventas: primero los de mayor ganancia y al final los de dato
  /// incompleto.
  List<FilaMargen> get filas => _filas;

  /// Suma de los productos con costo; no cuenta los incompletos.
  Decimal get gananciaTotal => _filas.fold(
    Decimal.zero,
    (suma, fila) => suma + (fila.margen ?? Decimal.zero),
  );

  int get productosConVentas => _filas.length;

  int get productosSinCosto => _filas.where((f) => f.margen == null).length;

  /// Mayor ganancia, para dibujar las barras; cero si ninguna es positiva.
  Decimal get mayorGanancia => _filas.fold(
    Decimal.zero,
    (mayor, fila) =>
        fila.margen != null && fila.margen! > mayor ? fila.margen! : mayor,
  );

  /// Cambia el periodo y consulta. [PeriodoMargen.fechas] se elige con
  /// [elegirFechas].
  Future<void> elegirPeriodo(PeriodoMargen periodo) {
    if (periodo == PeriodoMargen.fechas) {
      if (_desdeElegido == null) return Future.value();
    }
    _periodo = periodo;
    return cargar();
  }

  /// Rango de fechas propio; [ultimo] se incluye en el periodo.
  Future<void> elegirFechas(DateTime primero, DateTime ultimo) {
    _desdeElegido = DateTime(primero.year, primero.month, primero.day);
    _hastaElegido = DateTime(ultimo.year, ultimo.month, ultimo.day + 1);
    _periodo = PeriodoMargen.fechas;
    return cargar();
  }

  void _fijarPeriodo() {
    final ahora = _reloj();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final manana = DateTime(hoy.year, hoy.month, hoy.day + 1);
    final (desde, hasta) = switch (_periodo) {
      PeriodoMargen.hoy => (hoy, manana),
      PeriodoMargen.semana => (
        DateTime(hoy.year, hoy.month, hoy.day - (diasSemana - 1)),
        manana,
      ),
      PeriodoMargen.mes => (DateTime(hoy.year, hoy.month), manana),
      PeriodoMargen.fechas => (_desdeElegido!, _hastaElegido!),
    };
    _desde = desde;
    _hasta = hasta;
  }

  /// Consulta el margen del periodo elegido.
  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    _fijarPeriodo();
    notifyListeners();
    try {
      final margenes = await _coordinador.consultarMargen(
        _usuarioActivo.tienda,
        _desde,
        _hasta,
        _usuarioActivo.usuario,
      );
      _filas = [
        for (final e in margenes.entries) (producto: e.key, margen: e.value),
      ]..sort(_comparar);
    } on ExcepcionSoloPropietario {
      _filas = const [];
      _error = mensajeSoloPropietario;
    } on ExcepcionNegocio catch (e) {
      _filas = const [];
      _error = e.mensaje;
    } catch (_) {
      _filas = const [];
      _error = _mensajeFalla;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  static int _comparar(FilaMargen a, FilaMargen b) {
    final ma = a.margen;
    final mb = b.margen;
    if (ma == null && mb == null) {
      return a.producto.getNombre().compareTo(b.producto.getNombre());
    }
    if (ma == null) return 1;
    if (mb == null) return -1;
    return mb.compareTo(ma);
  }
}
