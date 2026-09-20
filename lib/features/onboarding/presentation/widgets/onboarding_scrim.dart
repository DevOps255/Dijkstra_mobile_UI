import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Voile de dégradé superposé à la vidéo pour garantir un contraste
/// suffisant (WCAG AA minimum) entre le texte blanc lavande et le
/// fond filmé, quelle que soit la luminosité de la séquence vidéo
/// à l'instant T.
class OnboardingScrim extends StatelessWidget {
  const OnboardingScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.onboardingScrim),
    );
  }
}
