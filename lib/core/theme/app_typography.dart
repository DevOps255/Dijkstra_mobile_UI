import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Système typographique unique du projet.
///
/// Source de vérité : spec établie en Leçon 41 (interface admin) —
/// `Inter` 600 / tracking -0.02em pour les titres, `Inter` 400 pour
/// le corps, `JetBrains Mono` pour toute donnée numérique (compteurs,
/// horodatages, tarifs). Cette classe est la seule autorisée à
/// instancier des `TextStyle` — aucun widget ne doit définir de style
/// de police inline.
abstract final class AppTypography {
  static TextStyle _base({
    required double size,
    required FontWeight weight,
    double letterSpacing = 0,
    double? height,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: color ?? AppColors.textPrimary,
    );
  }

  // ── Display / Titres ──────────────────────────────────────────────
  static TextStyle get displayLarge => _base(
        size: 32,
        weight: FontWeight.w700,
        letterSpacing: -0.64, // -0.02em
        height: 1.15,
      );

  static TextStyle get displayMedium => _base(
        size: 26,
        weight: FontWeight.w600,
        letterSpacing: -0.52,
        height: 1.2,
      );

  static TextStyle get headline => _base(
        size: 20,
        weight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.25,
      );

  // ── Corps ─────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => _base(
        size: 16,
        weight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodyMedium => _base(
        size: 14,
        weight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => _base(
        size: 12,
        weight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textTertiary,
      );

  // ── Boutons / Labels ──────────────────────────────────────────────
  static TextStyle get button => _base(
        size: 16,
        weight: FontWeight.w600,
        letterSpacing: -0.16,
        color: AppColors.textPrimary,
      );

  static TextStyle get label => _base(
        size: 13,
        weight: FontWeight.w500,
        letterSpacing: 0.1,
        color: AppColors.textSecondary,
      );

  // ── Données numériques (monospace) ───────────────────────────────
  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
    );
  }

  // ── Wordmark — nom de l'app, imposant, tracking très serré ────────
  // Registre visuel WhatsApp/Netflix/YouTube : graisse maximale,
  // letter-spacing négatif prononcé. On reste sur Inter (cohérence
  // du système typographique) plutôt que d'introduire une police
  // dédiée — le poids + le tracking suffisent à obtenir ce rendu
  // "condensé professionnel" sans dépendance supplémentaire.
  static TextStyle get wordmark => _base(
        size: 25,
        weight: FontWeight.w800,
        letterSpacing: -0.9,
      );

  const AppTypography._();
}
