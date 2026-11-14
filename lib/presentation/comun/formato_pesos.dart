import 'package:decimal/decimal.dart';

/// Precio como lo escribe el tendero: miles con punto y decimales con coma
/// (3500.5 → "3.500,5"). Sin el signo de pesos.
String mostrarPrecio(Decimal valor) {
  final partes = valor.toString().split('.');
  final entero = partes.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return partes.length > 1 ? '$entero,${partes[1]}' : entero;
}

/// Convierte un valor en pesos escrito por el tendero: el punto separa miles y
/// la coma, decimales. Acepta "$", espacios y el signo menos (los servicios
/// rechazan los negativos). Devuelve null si no es un número.
Decimal? leerPesos(String texto) {
  final limpio = texto
      .replaceAll(r'$', '')
      .replaceAll(RegExp(r'\s'), '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(limpio)) return null;
  return Decimal.parse(limpio);
}
