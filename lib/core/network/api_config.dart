import 'package:flutter/foundation.dart';

/// URL de base de l'API Bus Campus.
///
/// DEV  : URL ngrok de ta session courante (voir L22C, Partie 5.2) —
///        change à chaque redémarrage de ngrok en free tier.
/// PROD : domaine réel, HTTPS obligatoire.
///
/// Ne JAMAIS coder l'URL en dur dans un widget — toujours passer par
/// cette classe, et toujours lancer Flutter avec `--dart-define`.
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
    // 10.0.2.2 = alias standard de "localhost de ta machine hôte"
    // depuis l'émulateur Android Studio. Sur appareil physique,
    // remplace impérativement par ton URL ngrok — voir README.
  );

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 12);

  /// Vérifie que la configuration réseau est sûre pour un build de
  /// production — appelée une fois au démarrage (voir `main.dart`).
  ///
  /// En mode release, une URL `http://` (non chiffrée) fait planter
  /// l'app immédiatement au démarrage plutôt que de laisser filer un
  /// build qui enverrait des identifiants en clair sur le réseau.
  /// En debug/profile, seul un avertissement est loggué — nécessaire
  /// pour le développement local (`10.0.2.2`, ngrok en HTTP).
  static void assertSecureInRelease() {
    final isSecure = baseUrl.startsWith('https://');

    if (kReleaseMode && !isSecure) {
      throw StateError(
        'ApiConfig.assertSecureInRelease : build de production avec '
        'une URL API non chiffrée ($baseUrl). Relance avec '
        '--dart-define=API_BASE_URL=https://... — jamais de build '
        'release en HTTP, les tokens circuleraient en clair.',
      );
    }

    if (!kReleaseMode && !isSecure) {
      debugPrint(
        'ApiConfig : URL API non chiffrée ($baseUrl) — acceptable en '
        'développement local uniquement.',
      );
    }
  }

  const ApiConfig._();
}
