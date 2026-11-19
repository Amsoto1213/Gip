import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Idioma de la app: español. Sin esto, los componentes de Material que traen
/// sus propios textos (el selector de fechas de "Ventas de hoy") no encuentran
/// sus traducciones y fallan al abrirse.
const idiomasGip = [Locale('es')];

/// Traducciones de Material, de los widgets básicos y de Cupertino en español.
const delegadosIdiomaGip = <LocalizationsDelegate<dynamic>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
