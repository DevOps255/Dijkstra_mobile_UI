import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

/// Point d'entrée unique de la configuration DI.
///
/// `injectable` génère `injection.config.dart` via
/// `dart run build_runner build --delete-conflicting-outputs`.
/// Ce fichier n'est volontairement PAS écrit à la main  toute
/// modification manuelle sera écrasée à la prochaine génération.
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() => getIt.init();
