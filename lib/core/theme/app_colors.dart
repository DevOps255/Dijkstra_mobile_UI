import 'package:flutter/material.dart';

/// Palette Bus Campus — light ET dark, basculable à l'exécution.
///
/// Choix d'architecture : des champs `static` MUTABLES (pas `const`)
/// plutôt qu'un `ThemeExtension` + `Theme.of(context)` partout.
/// Raison pragmatique : la majorité du projet référence déjà
/// `AppColors.primary` etc. comme des constantes statiques, y compris
/// dans des `CustomPainter` qui n'ont pas de `BuildContext` sous la
/// main. Migrer vers `ThemeExtension` demanderait de récrire une
/// trentaine de fichiers avec un vrai risque de casse. Cette approche
/// bascule TOUTES les valeurs d'un coup via [updateForBrightness],
/// appelé une fois au démarrage puis à chaque changement de
/// luminosité système (voir `BrightnessObserver`).
abstract final class AppColors {
  // ── Fond ──────────────────────────────────────────────────────────
  static Color background = _light.background;
  static Color surface = _light.surface;
  static Color surfaceElevated = _light.surfaceElevated;

  // ── Accent — identique dans les deux thèmes, reconnaissance de marque
  static const Color primary = Color(0xFF2F6BFF);
  static const Color primaryVariant = Color(0xFF1E4FD9);
  static Color primarySubtle = _light.primarySubtle;

  // ── Texte ─────────────────────────────────────────────────────────
  static Color textPrimary = _light.textPrimary;
  static Color textSecondary = _light.textSecondary;
  static Color textTertiary = _light.textTertiary;

  // ── États sémantiques — stables dans les deux thèmes ────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  // ── Structure ─────────────────────────────────────────────────────
  static Color divider = _light.divider;
  static Color cardShadow = _light.cardShadow;

  // ── Contexte "sur média sombre" (vidéo d'onboarding) — invariant,
  // ne dépend jamais du thème puisque la vidéo est toujours sombre.
  static const Color onVideoPrimary = Color(0xFFF5F4FA);
  static const Color onVideoSecondary = Color(0xFFC7C6D6);

  static const LinearGradient onboardingScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.45, 0.75, 1.0],
    colors: [
      Color(0x00000000),
      Color(0x73000000),
      Color(0xE6000000),
      Color(0xFF000000),
    ],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D7BFF), Color(0xFF2456E0)],
  );

  /// Applique la palette correspondant à [brightness]. Appelé au
  /// démarrage (voir `main.dart`) et à chaque changement détecté par
  /// `BrightnessObserver`.
  static void updateForBrightness(Brightness brightness) {
    final palette = paletteFor(brightness);
    background = palette.background;
    surface = palette.surface;
    surfaceElevated = palette.surfaceElevated;
    primarySubtle = palette.primarySubtle;
    textPrimary = palette.textPrimary;
    textSecondary = palette.textSecondary;
    textTertiary = palette.textTertiary;
    divider = palette.divider;
    cardShadow = palette.cardShadow;
  }

  /// Accès public aux deux palettes, INDÉPENDANT de l'état courant —
  /// utilisé par `AppTheme.light`/`AppTheme.dark` pour construire deux
  /// `ThemeData` toujours corrects, même si l'app est actuellement en
  /// dark (sinon `AppTheme.light` hériterait par erreur des couleurs
  /// sombres courantes).
  static _Palette paletteFor(Brightness brightness) {
    return brightness == Brightness.dark ? _dark : _light;
  }

  static const _Palette _light = _Palette(
    background: Color(0xFFFAFAFF),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF3F2FA),
    primarySubtle: Color(0x142F6BFF),
    textPrimary: Color(0xFF14141C),
    textSecondary: Color(0xFF6B6B80),
    textTertiary: Color(0xFF9E9EB0),
    divider: Color(0xFFE7E6F0),
    cardShadow: Color(0x1414141C),
  );

  /// Dark "pensé", pas "dark pour être dark" : fond bleu-nuit profond
  /// (pas un noir pur — un noir pur écrase toute hiérarchie visuelle),
  /// halo bleu de marque conservé (voir `AuthBackground`), icônes et
  /// accents qui restent lumineux plutôt que ternes.
  static const _Palette _dark = _Palette(
    background: Color(0xFF0A0A0F),
    surface: Color(0xFF14141C),
    surfaceElevated: Color(0xFF1D1D28),
    primarySubtle: Color(0x262F6BFF),
    textPrimary: Color(0xFFF5F4FA),
    textSecondary: Color(0xFFA8A8BC),
    textTertiary: Color(0xFF6E6E82),
    divider: Color(0xFF25252F),
    cardShadow: Color(0x40000000),
  );

  const AppColors._();
}

class _Palette {
  const _Palette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.primarySubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.cardShadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color primarySubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;
  final Color cardShadow;
}
