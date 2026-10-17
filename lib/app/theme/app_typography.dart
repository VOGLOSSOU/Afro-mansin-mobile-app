import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typographie de l'app — seul endroit où les polices sont nommées.
///
/// Règles :
/// - Fraunces = uniquement titres et noms de plantes en gros. Jamais pour du
///   texte courant ni des boutons.
/// - NotoSans = tout le reste.
/// - Noms en langues locales (fon, yoruba, goun…) toujours en NotoSans, même
///   dans un titre : Fraunces n'a pas ɛ ɔ ɖ Ɖ Ɔ ǹ.
/// - Noms scientifiques toujours en italique ([scientificName]).
///
/// Dans les widgets, toujours partir de `Theme.of(context).textTheme.xxx`.
class AppTypography {
  AppTypography._();

  static const String titles = 'Fraunces';
  static const String body = 'NotoSans';

  // Si un caractère local passe dans un titre, NotoSans prend le relais
  // plutôt qu'une police de secours quelconque du téléphone.
  static const List<String> _titlesFallback = [body];

  static const TextTheme textTheme = TextTheme(
    // Titre écran / nom de plante (fiche)
    headlineLarge: TextStyle(
      fontFamily: titles,
      fontFamilyFallback: _titlesFallback,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    // Titre de section
    headlineMedium: TextStyle(
      fontFamily: titles,
      fontFamilyFallback: _titlesFallback,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
    // Nom de plante dans une carte
    titleMedium: TextStyle(
      fontFamily: titles,
      fontFamilyFallback: _titlesFallback,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
    // Texte courant
    bodyLarge: TextStyle(
      fontFamily: body,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    // Texte secondaire
    bodyMedium: TextStyle(
      fontFamily: body,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
    // Boutons, onglets, labels
    labelLarge: TextStyle(
      fontFamily: body,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.2,
    ),
    // Légendes, badges
    labelSmall: TextStyle(
      fontFamily: body,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
  );

  /// Nom scientifique (ex. *Vernonia amygdalina*) — italique, convention botanique.
  static const TextStyle scientificName = TextStyle(
    fontFamily: titles,
    fontFamilyFallback: _titlesFallback,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 1.4,
    color: AppColors.textSecondary,
  );
}
