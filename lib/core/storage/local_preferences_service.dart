import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_assets.dart';

/// Préférences locales non sensibles (flags UI, dernière langue
/// sélectionnée, etc.). Ne jamais y stocker un token ou un secret —
/// voir [SecureStorageService] pour ce cas.
@lazySingleton
class LocalPreferencesService {
  const LocalPreferencesService(this._prefs);

  final SharedPreferences _prefs;

  bool get hasSeenOnboarding =>
      _prefs.getBool(AppStorageKeys.hasSeenOnboarding) ?? false;

  Future<void> setOnboardingSeen() {
    return _prefs.setBool(AppStorageKeys.hasSeenOnboarding, true);
  }
}

/// Fournit l'instance `SharedPreferences` au conteneur d'injection.
/// L'initialisation asynchrone est réalisée avant `runApp` — voir
/// `main.dart` / `configureDependencies()`.
@module
abstract class PreferencesModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
