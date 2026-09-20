import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:injectable/injectable.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tente d'ouvrir l'application mail native de l'appareil.
///
/// Contrainte honnête : il n'existe aucune API cross-plateforme
/// garantissant l'ouverture du client mail par défaut quel qu'il
/// soit. La stratégie ici est heuristique et documentée comme telle :
///
/// - **Android** : intent `ACTION_MAIN` + catégorie `APP_EMAIL` — le
///   système affiche le client mail par défaut de l'utilisateur, ou
///   un sélecteur s'il y en a plusieurs. Couverture quasi totale.
/// - **iOS** : Apple n'expose aucune catégorie d'intent équivalente.
///   On teste successivement les schémas d'URL des clients mail les
///   plus répandus (`googlegmail://`, `message://` pour Mail.app,
///   `ms-outlook://`) et on ouvre le premier disponible. Si aucun
///   n'est détecté, on retourne `false` — à l'appelant d'afficher un
///   message invitant à ouvrir l'app manuellement, jamais un crash.
@lazySingleton
class MailAppLauncher {
  Future<bool> openMailApp() async {
    if (Platform.isAndroid) {
      return _openOnAndroid();
    }
    if (Platform.isIOS) {
      return _openOnIOS();
    }
    return false;
  }

  Future<bool> _openOnAndroid() async {
    try {
      const intent = AndroidIntent(
        action: 'action_main',
        category: 'android.intent.category.APP_EMAIL',
      );
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _openOnIOS() async {
    const candidateSchemes = <String>[
      'googlegmail://',
      'ms-outlook://',
      'message://', // Mail.app
    ];

    for (final scheme in candidateSchemes) {
      final uri = Uri.parse(scheme);
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri);
      }
    }
    return false;
  }
}
