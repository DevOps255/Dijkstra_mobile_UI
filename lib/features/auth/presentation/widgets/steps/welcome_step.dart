import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_logo_mark.dart';
import '../../../../../core/widgets/primary_gradient_button.dart';
import '../../../application/auth_flow_controller.dart';

/// Dernier écran du flux — accueil chaleureux avant d'entrer dans
/// l'application. Volontairement bref : l'animation joue une fois,
/// le bouton devient actif dès qu'elle est visible, jamais bloquant
/// si l'étudiant veut avancer plus vite.
class WelcomeStep extends ConsumerStatefulWidget {
  const WelcomeStep({super.key});

  @override
  ConsumerState<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends ConsumerState<WelcomeStep> {
  bool _lottieFailed = false;

  void _continue() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowControllerProvider);
    final firstName = state.fullName.isNotEmpty
        ? state.fullName.trim().split(' ').first
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AppWordmark(logoSize: 28),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 220,
                child: _lottieFailed
                    ? const _StaticWelcomeGlyph()
                    : Lottie.asset(
                        AppAssets.welcomeLottie,
                        repeat: false,
                        errorBuilder: (context, error, stackTrace) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _lottieFailed = true);
                            }
                          });
                          return const _StaticWelcomeGlyph();
                        },
                      ),
              ).animate().fadeIn(duration: const Duration(milliseconds: 420)),
              const SizedBox(height: 28),
              Text(
                firstName != null ? 'Bienvenue, $firstName.' : 'Bienvenue.',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 380),
                  )
                  .slideY(begin: 0.12, end: 0),
              const SizedBox(height: 10),
              Text(
                'Votre compte est prêt. Direction le campus.',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 380),
                  ),
              const Spacer(),
              PrimaryGradientButton(
                label: 'Continuer',
                onPressed: _continue,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticWelcomeGlyph extends StatelessWidget {
  const _StaticWelcomeGlyph();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryButtonGradient,
        ),
      ),
    );
  }
}
