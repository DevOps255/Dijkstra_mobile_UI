class WalletException implements Exception {
  const WalletException(this.publicMessage, [this.internalDetail]);

  final String publicMessage;
  final String? internalDetail;

  factory WalletException.network() => const WalletException(
        'Connexion impossible. Vérifiez votre réseau et réessayez.',
      );

  factory WalletException.generic() => const WalletException(
        'Une erreur est survenue. Réessayez dans un instant.',
      );

  factory WalletException.rechargeNotRecognized() => const WalletException(
        'Recharge non reconnue.',
      );

  @override
  String toString() => internalDetail ?? publicMessage;
}
