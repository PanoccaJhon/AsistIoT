import 'package:flutter/material.dart';

// Nota sobre los códigos de color en Flutter:
// Debes reemplazar el '#' con '0xFF'.
// 'FF' representa la opacidad (totalmente opaco).
// El resto son tus códigos de color RGB.

class AppColors {
  // Colores principales de tu paleta
  static const Color primary = Color(0xFF45B7BF);
  static const Color background = Color(0xFFF0F8F2);
  static const Color secondary = Color(0xFFA9D9D9);
  
  // Colores de acento y variaciones
  static const Color accentLight = Color(0xFFD5EFE2);
  static const Color secondaryMuted = Color(0xFFBCD9D3);

  // Colores estándar que son útiles
  static const Color textDark = Color(0xFF222222);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
}