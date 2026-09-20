import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_logo_mark.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../application/onboarding_controller.dart';
import '../../domain/onboarding_page_data.dart';
import '../widgets/onboarding_media_background.dart';
import '../widgets/onboarding_scrim.dart';
import '../widgets/onboarding_text_block.dart';

/// Écran affiché à la toute première ouverture de l'application.
///
/// Composition en couches (du fond vers le premier plan) :
/// 1. [OnboardingMediaBackground] — vidéo du bus en boucle, silencieuse
/// 2. [OnboardingScrim] — dégradé garantissant la lisibilité du texte
/// 3. Contenu — bouton "Passer", titre/description animés, indicateurs,
///    bouton d'action principal
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePrimaryAction() async {
    final state = ref.read(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    if (state.isLastPage) {
      await controller.completeOnboarding();
      if (mounted) context.go('/auth');
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleSkip() async {
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final pages = OnboardingContent.pages;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const OnboardingMediaBackground(),
          const OnboardingScrim(),

          // ── Marque — imposante, en haut à gauche, sur toute l'app ───
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, left: 20),
                child: AppWordmark(
                  logoSize: 30,
                  textColor: AppColors.onVideoPrimary,
                ),
              ),
            ),
          ),

          // ── Bouton "Passer" — texte seul, pas d'icône ──────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 20),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: state.isLastPage ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: state.isLastPage,
                    child: TextButton(
                      onPressed: _handleSkip,
                      child: Text(
                        'Passer',
                        style: AppTypography.label.copyWith(
                          color: AppColors.onVideoPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Contenu principal ───────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Expanded(
                  flex: 5,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      ref
                          .read(onboardingControllerProvider.notifier)
                          .onPageChanged(index);
                    },
                    itemBuilder: (context, index) {
                      return Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: OnboardingTextBlock(
                              key: ValueKey<int>(index),
                              data: pages[index],
                              pageIndex: index,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 28),

                SmoothPageIndicator(
                  controller: _pageController,
                  count: pages.length,
                  effect: const ExpandingDotsEffect(
                    dotHeight: 6,
                    dotWidth: 6,
                    expansionFactor: 3.4,
                    spacing: 6,
                    activeDotColor: AppColors.primary,
                    dotColor: AppColors.onVideoSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PrimaryGradientButton(
                    label: state.isLastPage ? 'Get Started' : 'Continuer',
                    onPressed: _handlePrimaryAction,
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
