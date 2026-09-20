import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/auth_flow_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/map/presentation/screens/map_home_screen.dart';
import '../../features/tickets/presentation/screens/tickets_list_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../di/injection.dart';
import '../storage/auth_session_store.dart';
import '../storage/local_preferences_service.dart';

/// Routeur unique de l'application.
///
/// Trois zones distinctes, évaluées dans cet ordre par `redirect` :
/// 1. Onboarding non vu → forcé vers `/`
/// 2. Onboarding vu mais non authentifié → forcé vers `/auth`
/// 3. Authentifié → jamais renvoyé vers `/` ou `/auth`
final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionStore = getIt<AuthSessionStore>();

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: _ValueNotifierRouterListenable(
      sessionStore.isAuthenticated,
    ),
    redirect: (context, state) {
      final hasSeenOnboarding =
          getIt<LocalPreferencesService>().hasSeenOnboarding;
      final isAuthenticated = sessionStore.isAuthenticated.value;

      final location = state.matchedLocation;
      final isOnboardingRoute = location == '/';
      final isAuthRoute = location == '/auth';

      if (!hasSeenOnboarding && !isOnboardingRoute) {
        return '/';
      }
      if (hasSeenOnboarding && !isAuthenticated && !isAuthRoute) {
        return '/auth';
      }
      if (isAuthenticated && (isOnboardingRoute || isAuthRoute)) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthFlowScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: 'wallet',
            name: 'wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: 'tickets',
            name: 'tickets',
            builder: (context, state) => const TicketsListScreen(),
          ),
          GoRoute(
            path: 'map',
            name: 'map',
            builder: (context, state) => const MapHomeScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Pont entre un `ValueNotifier<bool>` (session) et l'API
/// `Listenable` attendue par `GoRouter.refreshListenable` — permet au
/// routeur de ré-évaluer `redirect` automatiquement dès qu'un login
/// ou un logout change l'état de session, sans navigation manuelle
/// dispersée dans les écrans.
class _ValueNotifierRouterListenable extends ChangeNotifier {
  _ValueNotifierRouterListenable(this._source) {
    _source.addListener(notifyListeners);
  }

  final ValueNotifier<bool> _source;

  @override
  void dispose() {
    _source.removeListener(notifyListeners);
    super.dispose();
  }
}
