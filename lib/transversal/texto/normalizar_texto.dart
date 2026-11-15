/// Texto en minúsculas, sin tildes ni diéresis y con un solo espacio entre
/// palabras. Se guarda junto al nombre para buscar sin importar cómo se
/// escriba (RD-08). La ñ se conserva: en español es otra letra.
String normalizarTexto(String texto) {
  const conTilde = 'áàäâéèëêíìïîóòöôúùüû';
  const sinTilde = 'aaaaeeeeiiiioooouuuu';
  final minusculas = texto.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final caracter in minusculas.split('')) {
    final i = conTilde.indexOf(caracter);
    buffer.write(i >= 0 ? sinTilde[i] : caracter);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
}
