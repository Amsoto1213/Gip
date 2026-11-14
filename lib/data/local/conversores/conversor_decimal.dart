import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

/// Guarda dinero y cantidades como TEXT para no perder precisión (DI-02).
class ConversorDecimal extends TypeConverter<Decimal, String> {
  const ConversorDecimal();

  @override
  Decimal fromSql(String fromDb) => Decimal.parse(fromDb);

  @override
  String toSql(Decimal value) => value.toString();
}
