import 'package:gip/business/entidades/info_tienda/tipo_conflicto.dart';

/// Choque detectado al sincronizar que solo una persona puede decidir; se
/// guarda y se muestra al propietario (CUS-22). Su id es determinista (tipo y
/// registros) para que dos dispositivos no creen el mismo conflicto dos veces
/// (DA-48).
///
/// [getEtiquetasRegistros] no está en EA: una línea de texto por cada id de
/// [getIdsRegistros], en el mismo orden, que escribe quien detecta el conflicto
/// ("Entrada de 24 huevos · factura FV-10231 · 10:42 a. m."). Con ellas la
/// pantalla muestra cada registro sin tener que buscarlo (DI-45).
class ConflictoSincronizacion {
  /// [etiquetasRegistros] debe tener tantos textos como [idsRegistros]; si no
  /// se dan, cada registro se llama "Registro N" (DI-45). [fecha] va en UTC.
  ConflictoSincronizacion(
    this._id,
    this._tipo,
    this._descripcion,
    List<String> idsRegistros,
    this._fecha, {
    List<String>? etiquetasRegistros,
    this._resuelto = false,
  }) : _idsRegistros = List.unmodifiable(idsRegistros),
       _etiquetasRegistros = List.unmodifiable(
         _etiquetasPara(idsRegistros, etiquetasRegistros),
       );

  final String _id;
  final TipoConflicto _tipo;
  final String _descripcion;
  final List<String> _idsRegistros;
  final List<String> _etiquetasRegistros;
  final DateTime _fecha;
  bool _resuelto;

  static List<String> _etiquetasPara(List<String> ids, List<String>? dadas) {
    if (dadas == null) {
      return [for (var i = 0; i < ids.length; i++) 'Registro ${i + 1}'];
    }
    if (dadas.length != ids.length) {
      throw ArgumentError(
        'Hay ${ids.length} registros y ${dadas.length} etiquetas',
      );
    }
    return dadas;
  }

  /// Identificador del conflicto.
  String getId() => _id;

  /// Tipo de choque.
  TipoConflicto getTipo() => _tipo;

  /// Explicación en el lenguaje del tendero (RNF-25).
  String getDescripcion() => _descripcion;

  /// Ids de los registros involucrados.
  List<String> getIdsRegistros() => _idsRegistros;

  /// Un texto por registro, en el orden de [getIdsRegistros] (DI-45).
  List<String> getEtiquetasRegistros() => _etiquetasRegistros;

  /// Texto del registro con ese id, o nulo si no es de este conflicto.
  String? getEtiquetaDe(String idRegistro) {
    final i = _idsRegistros.indexOf(idRegistro);
    return i < 0 ? null : _etiquetasRegistros[i];
  }

  /// Fecha en que se detectó, en UTC.
  DateTime getFecha() => _fecha;

  /// Verdadero si el propietario ya lo resolvió.
  bool isResuelto() => _resuelto;

  /// Lo llama `ServicioConciliacion.resolverConflicto`.
  void setResuelto(bool resuelto) => _resuelto = resuelto;
}
