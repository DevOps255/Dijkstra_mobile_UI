class TicketException implements Exception {
  const TicketException(this.publicMessage, [this.internalDetail]);

  final String publicMessage;
  final String? internalDetail;

  factory TicketException.network() =>
      const TicketException('Connexion impossible. Vérifiez votre réseau et réessayez.');

  factory TicketException.generic() =>
      const TicketException('Une erreur est survenue. Réessayez dans un instant.');

  factory TicketException.invalidTicket() =>
      const TicketException('Ticket invalide.');

  @override
  String toString() => internalDetail ?? publicMessage;
}
