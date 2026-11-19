import 'package:flutter/foundation.dart';
import 'package:gip/business/entidades/gestion_caja/rotacion.dart';
import 'package:gip/business/entidades/gestion_inventario/producto.dart';
import 'package:gip/business/entidades/info_tienda/usuario_activo.dart';
import 'package:gip/business/workflow/gestion_caja/consultar_rotacion_coordinator.dart';
import 'package:gip/transversal/errores/errores_acceso.dart';
import 'package:gip/transversal/errores/excepcion_negocio.dart';

/// Periodos que ofrece la pantalla Rotación de productos.
enum PeriodoRotacion { dias30, mes, fechas }

/// Estado de la pantalla Rotación de productos (CUS-12). Llama solo a
/// [ConsultarRotacionCoordinator]. El periodo va de `desde` a `hasta` sin
/// incluir `hasta` (DI-28), en días locales.
///
/// El caso de uso entrega solo el grupo de cada producto, no sus unidades
/// (DI-40): la pantalla muestra los nombres en el orden en que llegan, de mayor
/// a menor venta.
class RotacionViewModel extends ChangeNotifier {
  RotacionViewModel(
    this._coordinador,
    this._usuarioActivo, {
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now {
    _fijarPeriodo();
  }

  /// Mensaje del diagrama cuando no es el propietario (CUS-05, paso 7).
  static const mensajeSoloPropietario =
      'Esta consulta es solo para el propietario';

  static const mensajeSinProductos = 'Todavía no hay productos registrados';

  static const _mensajeFalla =
      'No se pudo calcular la rotación. Intente de nuevo';

  /// "30 días" son los últimos 30 días, contando hoy (DI-40).
  static const diasPeriodo = 30;

  final ConsultarRotacionCoordinator _coordinador;
  final UsuarioActivo _usuarioActivo;
  final DateTime Function() _reloj;

  bool _cargando = false;
  String? _error;
  PeriodoRotacion _periodo = PeriodoRotacion.dias30;
  Rotacion _grupo = Rotacion.alta;
  DateTime? _desdeElegido;
  DateTime? _hastaElegido;
  late DateTime _desde;
  late DateTime _hasta;
  Map<Rotacion, List<Producto>> _grupos = _vacios();

  static Map<Rotacion, List<Producto>> _vacios() => {
    for (final r in Rotacion.values) r: const <Producto>[],
  };

  bool get cargando => _cargando;

  /// Mensaje para el tendero si la consulta no se pudo hacer.
  String? get error => _error;
  PeriodoRotacion get periodo => _periodo;

  /// Grupo que se ve en el móvil.
  Rotacion get grupo => _grupo;

  /// Primer día del periodo mostrado (incluido).
  DateTime get desde => _desde;

  /// Último día del periodo mostrado (incluido).
  DateTime get ultimoDia => DateTime(_hasta.year, _hasta.month, _hasta.day - 1);

  /// Productos del grupo, del que más vendió al que menos.
  List<Producto> productosDe(Rotacion grupo) => _grupos[grupo]!;

  int cantidadDe(Rotacion grupo) => _grupos[grupo]!.length;

  int get totalProductos =>
      Rotacion.values.fold(0, (s, g) => s + cantidadDe(g));

  /// Cambia el grupo que se ve (solo móvil); no vuelve a consultar.
  void elegirGrupo(Rotacion grupo) {
    _grupo = grupo;
    notifyListeners();
  }

  /// Cambia el periodo y consulta. [PeriodoRotacion.fechas] se elige con
  /// [elegirFechas].
  Future<void> elegirPeriodo(PeriodoRotacion periodo) {
    if (periodo == PeriodoRotacion.fechas && _desdeElegido == null) {
      return Future.value();
    }
    _periodo = periodo;
    return cargar();
  }

  /// Rango de fechas propio; [ultimo] se incluye en el periodo.
  Future<void> elegirFechas(DateTime primero, DateTime ultimo) {
    _desdeElegido = DateTime(primero.year, primero.month, primero.day);
    _hastaElegido = DateTime(ultimo.year, ultimo.month, ultimo.day + 1);
    _periodo = PeriodoRotacion.fechas;
    return cargar();
  }

  void _fijarPeriodo() {
    final ahora = _reloj();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final manana = DateTime(hoy.year, hoy.month, hoy.day + 1);
    final (desde, hasta) = switch (_periodo) {
      PeriodoRotacion.dias30 => (
        DateTime(hoy.year, hoy.month, hoy.day - (diasPeriodo - 1)),
        manana,
      ),
      PeriodoRotacion.mes => (DateTime(hoy.year, hoy.month), manana),
      PeriodoRotacion.fechas => (_desdeElegido!, _hastaElegido!),
    };
    _desde = desde;
    _hasta = hasta;
  }

  /// Consulta la rotación del periodo elegido.
  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    _fijarPeriodo();
    notifyListeners();
    try {
      final rotacion = await _coordinador.consultarRotacion(
        _usuarioActivo.tienda,
        _desde,
        _hasta,
        _usuarioActivo.usuario,
      );
      final grupos = {for (final r in Rotacion.values) r: <Producto>[]};
      for (final e in rotacion.entries) {
        grupos[e.value]!.add(e.key);
      }
      _grupos = grupos;
    } on ExcepcionSoloPropietario {
      _grupos = _vacios();
      _error = mensajeSoloPropietario;
    } on ExcepcionNegocio catch (e) {
      _grupos = _vacios();
      _error = e.mensaje;
    } catch (_) {
      _grupos = _vacios();
      _error = _mensajeFalla;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
