import 'package:flutter/material.dart';

// Paleta de la app. Cada tono indigo tiene la misma luminancia que el tono
// lime que reemplaza, para conservar el texto negro sobre los fondos.
class AppColors {
  AppColors._();

  static const MaterialColor indigo = MaterialColor(0xFFBFCEFE, {
    50: Color(0xFFF7F9FE),
    100: Color(0xFFEAEFFF),
    200: Color(0xFFDDE5FF),
    300: Color(0xFFD0DCFF),
    400: Color(0xFFC7D4FE),
    500: Color(0xFFBFCEFE),
    600: Color(0xFFA9BCFE),
    700: Color(0xFF8EA6FF),
    800: Color(0xFF728DFE),
    900: Color(0xFF495BFF),
  });
}
