import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === COULEURS PRINCIPALES ===
  static const Color primary        = Color(0xFF2E6B3F); // Vert forêt — plantes
  static const Color primaryDark    = Color(0xFF1F4A2B);
  static const Color primarySurface = Color(0xFFE8F0E9);

  // === SECONDAIRE & ACCENT ===
  static const Color secondary      = Color(0xFFB5582A); // Terracotta — terre rouge
  static const Color accent         = Color(0xFFD9A441); // Ocre — icônes audio, badges

  // === FOND & SURFACES ===
  static const Color white          = Color(0xFFFFFFFF);
  static const Color background     = Color(0xFFFAF6EE); // Crème chaud
  static const Color surface        = Color(0xFFFFFFFF);

  // === TEXTES ===
  static const Color textPrimary    = Color(0xFF2B2118); // Brun très foncé
  static const Color textSecondary  = Color(0xFF6E6259);
  static const Color textOnPrimary  = Color(0xFFFFFFFF);

  // === ÉTATS ===
  // Rouge réservé aux urgences et mises en garde — ne pas l'utiliser ailleurs
  // pour qu'il garde tout son poids.
  static const Color danger         = Color(0xFFB3261E);

  // === BORDURES ===
  static const Color border         = Color(0xFFE6DDD0);
}
