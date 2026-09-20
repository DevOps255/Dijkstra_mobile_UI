/// Chemins d'assets centralisés — aucune chaîne littérale de chemin
/// d'asset ne doit apparaître ailleurs dans le code.
abstract final class AppAssets {
  // Vidéo du bus utilisée en fond d'écran d'onboarding.
  // Format recommandé : H.264, 720p max, < 8 Mo, sans piste audio
  // (le silence évite tout conflit avec le volume système de
  // l'étudiant et réduit le poids du fichier d'environ 30%).
  static const String onboardingBusVideo = 'assets/videos/bus_night.mp4';

  // Fallback Lottie si la vidéo ne peut pas être chargée (appareil
  // très bas de gamme, décodeur H.264 hardware absent, etc.)
  static const String onboardingBusLottie = 'assets/lottie/bus_loop.json';

  // Animation de bienvenue — écran final du flux d'authentification.
  // Distincte de la boucle bus : courte (2-3s), non répétée,
  // célébrative (ex: confettis discrets ou coche animée).
  static const String welcomeLottie = 'assets/lottie/welcome.json';

  const AppAssets._();
}

/// Durées d'animation centralisées — cohérence du "feel" dans toute
/// l'app.
abstract final class AppDurations {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 550);
  static const pageTransition = Duration(milliseconds: 420);

  const AppDurations._();
}

abstract final class AppStorageKeys {
  static const String hasSeenOnboarding = 'has_seen_onboarding';
  static const String secureAuthToken = 'secure_auth_token';
  static const String secureRefreshToken = 'secure_refresh_token';

  const AppStorageKeys._();
}
