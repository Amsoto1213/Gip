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
