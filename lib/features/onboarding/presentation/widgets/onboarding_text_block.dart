import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/onboarding_page_data.dart';

/// Titre + description avec animation d'entrée en fondu + léger
/// glissement vertical ("shading") — se rejoue à chaque changement
/// de page grâce à la `ValueKey` sur l'index.
class OnboardingTextBlock extends StatelessWidget {
  const OnboardingTextBlock({
    super.key,
    required this.data,
    required this.pageIndex,
  });

  final OnboardingPageData data;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey<int>(pageIndex),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.title,
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.onVideoPrimary,
          ),
        )
            .animate()
            .fadeIn(
              duration: AppDurations.slow,
              curve: Curves.easeOutCubic,
            )
            .slideY(
              begin: 0.18,
              end: 0,
              duration: AppDurations.slow,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 14),
        Text(
          data.description,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.onVideoSecondary,
          ),
        )
            .animate()
            .fadeIn(
              delay: const Duration(milliseconds: 120),
              duration: AppDurations.slow,
              curve: Curves.easeOutCubic,
            )
            .slideY(
              begin: 0.18,
              end: 0,
              delay: const Duration(milliseconds: 120),
              duration: AppDurations.slow,
              curve: Curves.easeOutCubic,
            ),
      ],
    );
  }
}
