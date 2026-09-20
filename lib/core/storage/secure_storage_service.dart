import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Enveloppe autour de `flutter_secure_storage`.
///
/// Réservé aux données sensibles à durée de vie longue (tokens JWT,
/// clés de portefeuille — cf. logique déjà validée en L42B pour le
/// wallet chauffeur). Les indicateurs non sensibles (ex: onboarding
/// déjà vu) passent par `shared_preferences`, jamais par ce service —
/// mélanger les deux dilue la garantie de sécurité qu'offre le
/// Keystore/Keychain.
@lazySingleton
class SecureStorageService {
  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  final FlutterSecureStorage _storage;

  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error) {
      // Le Keystore Android peut se corrompre après une restauration
      // de sauvegarde, un changement d'empreinte biométrique système,
      // ou une réinitialisation partielle de l'appareil. sans ceci
      // l'app planterait au démarrage à chaque tentative
      // d'écriture
      debugPrint('SecureStorageService.write : échec pour "$key" : $error');
    }
  }

  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (error) {
      debugPrint('SecureStorageService.read : échec pour "$key" : $error');
      return null;
    }
  }

  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (error) {
      debugPrint('SecureStorageService.delete : échec pour "$key" : $error');
    }
  }

  /// Purge totale — utilisée à la déconnexion complète ou à la
  /// détection d'une intégrité compromise (Keystore illisible).
  Future<void> wipeAll() async {
    try {
      await _storage.deleteAll();
    } catch (error) {
      debugPrint('SecureStorageService.wipeAll : échec : $error');
    }
  }
}
