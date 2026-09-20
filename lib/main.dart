import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_info.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/security/screenshot_protection.dart';
import 'core/storage/auth_session_store.dart';
import 'core/network/api_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/brightness_controller.dart';

/// Instance unique — créée avant `runApp`, sa luminosité initiale est
/// donc déjà appliquée à `AppColors` avant le tout premier frame
/// (élimine tout flash de mauvaise palette au démarrage).
final BrightnessController _brightnessController = BrightnessController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Premier contrôle de sécurité — avant tout autre setup. Fait
  // planter immédiatement un build release mal configuré plutôt que
  // de laisser filer une app qui parlerait en clair sur le réseau.
  ApiConfig.assertSecureInRelease();

  await configureDependencies();

  await ScreenshotProtection.enable();

  await getIt<AuthSessionStore>().restore();

  runApp(const ProviderScope(child: BusCampusApp()));
}

class BusCampusApp extends ConsumerWidget {
  const BusCampusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);

    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) {
        // `ListenableBuilder` force une reconstruction COMPLÈTE de
        // `MaterialApp.router` quand la luminosité système change en
        // cours d'exécution — nécessaire parce que `AppColors` est
        // un état mutable global (voir la note dans app_colors.dart),
        // pas un `Theme.of(context)` que Flutter rafraîchirait seul.
        return ListenableBuilder(
          listenable: _brightnessController,
          builder: (context, _) {
            return MaterialApp.router(
              title: AppInfo.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.system,
              routerConfig: router,
            );
          },
        );
      },
    );
  }
}
