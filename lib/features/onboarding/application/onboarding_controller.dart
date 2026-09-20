import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/storage/local_preferences_service.dart';
import '../domain/onboarding_page_data.dart';

/// État immuable de l'écran d'onboarding.
class OnboardingState {
  const OnboardingState({
    required this.currentPage,
    required this.isLastPage,
  });

  factory OnboardingState.initial() =>
      const OnboardingState(currentPage: 0, isLastPage: false);

  final int currentPage;
  final bool isLastPage;

  OnboardingState copyWith({int? currentPage, bool? isLastPage}) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      isLastPage: isLastPage ?? this.isLastPage,
    );
  }
}

/// Notifier manuel (pas de génération `riverpod_generator` requise
/// pour ce contrôleur volontairement simple — la génération est
/// réservée aux notifiers qui dépendent d'appels réseau asynchrones
/// ailleurs dans le projet).
class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => OnboardingState.initial();

  static final int totalPages = OnboardingContent.pages.length;

  void onPageChanged(int index) {
    state = state.copyWith(
      currentPage: index,
      isLastPage: index == totalPages - 1,
    );
  }

  /// Marque l'onboarding comme vu — persisté localement, non sensible.
  Future<void> completeOnboarding() async {
    await getIt<LocalPreferencesService>().setOnboardingSeen();
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
