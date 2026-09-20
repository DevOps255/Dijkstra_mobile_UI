import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../constants/app_assets.dart';
import 'current_user_profile.dart';
import 'secure_storage_service.dart';

/// Source de vérité unique de l'état de connexion.
///
/// L'access token vit en mémoire (`_accessToken`) pour un accès
/// synchrone rapide par l'intercepteur Dio, et est répliqué dans
/// [SecureStorageService] (Keystore/Keychain) pour survivre au
/// redémarrage de l'application — contrairement au web (L41) où le
/// JWT reste volontairement en mémoire de variable React (l'onglet
/// meurt à la fermeture), une app mobile doit rester connectée entre
/// deux ouvertures, donc le stockage Keystore est le choix correct
/// ici, pas une régression de sécurité.
///
/// Le refresh token, lui, ne transite JAMAIS par cette classe — il
/// vit exclusivement dans le cookie `HttpOnly` géré par le
/// `PersistCookieJar` (voir `dio_client.dart`), fidèle au contrat
/// backend de L22B.
@lazySingleton
class AuthSessionStore {
  AuthSessionStore(this._secureStorage);

  final SecureStorageService _secureStorage;

  String? _accessToken;

  final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);

  /// Profil affiché par l'accueil (avatar, prénom). `null` tant que
  /// non chargé — l'appelant (`HomeController`) déclenche
  /// `AuthRepository.getCurrentUser()` si besoin plutôt que de
  /// supposer une valeur par défaut.
  final ValueNotifier<CurrentUserProfile?> currentUser =
      ValueNotifier<CurrentUserProfile?>(null);

  String? get accessToken => _accessToken;

  void setCurrentUser(CurrentUserProfile profile) {
    currentUser.value = profile;
  }

  /// Restaure la session depuis le Keystore/Keychain au démarrage
  /// de l'application — appelé une fois, avant `runApp`.
  Future<void> restore() async {
    final token = await _secureStorage.read(
      key: AppStorageKeys.secureAuthToken,
    );
    if (token != null && token.isNotEmpty) {
      _accessToken = token;
      isAuthenticated.value = true;
    }
  }

  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    isAuthenticated.value = true;
    await _secureStorage.write(
      key: AppStorageKeys.secureAuthToken,
      value: token,
    );
  }

  /// Purge complète — déconnexion ou échec définitif de refresh.
  Future<void> clear() async {
    _accessToken = null;
    isAuthenticated.value = false;
    currentUser.value = null;
    await _secureStorage.delete(key: AppStorageKeys.secureAuthToken);
  }
}
