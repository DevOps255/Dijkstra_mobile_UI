import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app_colors.dart';

/// Observe la luminosité système (`Brightness.light`/`Brightness.dark`)
/// et synchronise `AppColors` en conséquence.
///
/// `ChangeNotifier` plutôt que Riverpod : ce contrôleur doit exister
/// et fonctionner AVANT que `ProviderScope`/le premier widget ne soit
/// monté (on applique la luminosité initiale dans `main()`, avant
/// `runApp`), donc un état Riverpod serait prématuré à ce stade du
/// cycle de vie.
class BrightnessController extends ChangeNotifier
    with WidgetsBindingObserver {
  BrightnessController() {
    WidgetsBinding.instance.addObserver(this);
    _apply(_currentPlatformBrightness);
  }

  Brightness _brightness = Brightness.light;
  Brightness get brightness => _brightness;

  Brightness get _currentPlatformBrightness {
    return SchedulerBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  void didChangePlatformBrightness() {
    _apply(_currentPlatformBrightness);
  }

  void _apply(Brightness brightness) {
    if (_brightness == brightness) return;
    _brightness = brightness;
    AppColors.updateForBrightness(brightness);
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
