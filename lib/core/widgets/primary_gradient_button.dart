import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'pressable_scale.dart';

/// Bouton d'action principal du projet.
///
/// Volontairement dépourvu de toute icône ou emoji — texte seul,
/// centré, sur fond dégradé bleu. Réutilisé partout où un CTA
/// primaire est nécessaire (onboarding, achat de ticket, etc.)
/// pour garantir une cohérence visuelle stricte.
///
/// Retour tactile via [PressableScale] (tap-down immédiat, jamais
/// au relâchement — principe n°1 du skill Apple Design) plutôt que
/// le splash Material par défaut, pour rester cohérent avec le
/// reste du projet (operator_picker_card, sélecteur de SIM...).
class PrimaryGradientButton extends StatelessWidget {
  const PrimaryGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool disabled = isLoading || onPressed == null;

    return PressableScale(
      onTap: disabled ? null : onPressed,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: disabled ? null : AppColors.primaryButtonGradient,
            color: disabled ? AppColors.surfaceElevated : null,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.textPrimary),
                    ),
                  )
                : Text(
                    label,
                    style: AppTypography.button.copyWith(
                      color: disabled
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
