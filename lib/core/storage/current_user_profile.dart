/// Profil minimal de l'utilisateur connecté, accessible depuis
/// `core/` sans dépendre du module `auth` (qui vit dans `features/`).
///
/// Règle de couplage identique à celle du backend (L33) : un module
/// `core` ne doit jamais importer depuis `features/`. C'est
/// `AuthRepository` (dans `features/auth`) qui traduit son
/// `AuthUser` complet vers ce type réduit au moment de le stocker
/// dans [AuthSessionStore].
class CurrentUserProfile {
  const CurrentUserProfile({
    required this.id,
    required this.email,
    required this.fullName,
  });

  final String id;
  final String email;
  final String fullName;
}
