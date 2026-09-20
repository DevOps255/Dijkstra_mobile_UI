import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animation/app_spring.dart';
import '../../application/auth_flow_controller.dart';
import '../widgets/auth_background.dart';
import '../widgets/steps/check_your_email_step.dart';
import '../widgets/steps/confirm_email_step.dart';
import '../widgets/steps/create_password_step.dart';
import '../widgets/steps/email_entry_step.dart';
import '../widgets/steps/full_name_step.dart';
import '../widgets/steps/login_password_step.dart';
import '../widgets/steps/welcome_step.dart';

/// Point d'entrée unique du flux d'authentification.
///
/// Une seule route GoRouter héberge les sept étapes — la navigation
/// entre elles est un changement d'état ([AuthStep]), pas une pile de
/// routes. Choix délibéré : ce flux est strictement linéaire côté
/// métier (pas de retour système attendu au milieu d'une saisie de
/// mot de passe), donc un `AnimatedSwitcher` piloté par ressort donne
/// la même fluidité qu'une vraie navigation, sans la complexité d'une
/// pile imbriquée à synchroniser avec l'état du contrôleur.
class AuthFlowScreen extends ConsumerWidget {
  const AuthFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(
      authFlowControllerProvider.select((s) => s.step),
    );

    return AuthBackground(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        switchInCurve: const SpringCurve(),
        switchOutCurve: const SpringCurve(),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<AuthStep>(step),
          child: _stepWidget(step),
        ),
      ),
    );
  }

  Widget _stepWidget(AuthStep step) {
    return switch (step) {
      AuthStep.emailEntry => const EmailEntryStep(),
      AuthStep.confirmEmail => const ConfirmEmailStep(),
      AuthStep.loginPassword => const LoginPasswordStep(),
      AuthStep.fullName => const FullNameStep(),
      AuthStep.createPassword => const CreatePasswordStep(),
      AuthStep.checkYourEmail => const CheckYourEmailStep(),
      AuthStep.welcome => const WelcomeStep(),
    };
  }
}
