/// Exception typée du module auth.
///
/// [publicMessage] est TOUJOURS ce qui est affiché à l'écran — jamais
/// de stack trace, jamais de message d'exception Dio brut. Miroir
/// exact de la convention `AuthError` déjà établie côté backend (L22,
/// `user_service.py`).
class AuthException implements Exception {
  const AuthException(this.publicMessage, [this.internalDetail]);

  final String publicMessage;
  final String? internalDetail;

  factory AuthException.network() => const AuthException(
        'Connexion impossible. Vérifiez votre réseau et réessayez.',
      );

  factory AuthException.generic() => const AuthException(
        'Une erreur est survenue. Réessayez dans un instant.',
      );

  @override
  String toString() => internalDetail ?? publicMessage;
}
