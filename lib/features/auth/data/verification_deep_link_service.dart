import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Écoute le custom URL scheme `buscampus://verified` déclenché par
/// la page de confirmation servie sur `GET /auth/verify` (L22B,
/// Partie 4 — redirection après le `POST /auth/verify` réussi).
///
/// Complémentaire aux Universal Links / App Links (L22B, Partie 2) —
/// ce mécanisme fonctionne même si le lien HTTPS initial n'a pas été
/// intercepté par l'app (ouvert dans le navigateur), tant que l'app
/// est installée et que le navigateur autorise la redirection vers
/// un scheme personnalisé.
@lazySingleton
class VerificationDeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  /// [onVerified] est appelé une seule fois par lien reçu, avec le
  /// contrôle laissé à l'appelant sur la suite (généralement :
  /// avancer le `AuthFlowController` vers l'étape de bienvenue).
  void startListening({required VoidCallback onVerified}) {
    _subscription?.cancel();
    _subscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'buscampus' && uri.host == 'verified') {
        onVerified();
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
