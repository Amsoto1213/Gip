const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Hora local de una fecha guardada en UTC.
DateTime _local(DateTime fecha) => fecha.toLocal();

/// "28 oct." (tres letras y punto).
String fechaCorta(DateTime fecha) {
  final f = _local(fecha);
  return '${f.day} ${_meses[f.month - 1].substring(0, 3)}.';
}

/// "28 de octubre".
String fechaLarga(DateTime fecha) {
  final f = _local(fecha);
  return '${f.day} de ${_meses[f.month - 1]}';
}
