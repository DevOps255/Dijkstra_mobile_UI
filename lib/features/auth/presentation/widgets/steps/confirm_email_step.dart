import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/pressable_scale.dart';
import '../../../../../core/widgets/primary_gradient_button.dart';
import '../../../application/auth_flow_controller.dart';
import '../auth_step_scaffold.dart';

class ConfirmEmailStep extends ConsumerWidget {
  const ConfirmEmailStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authFlowControllerProvider);
    final notifier = ref.read(authFlowControllerProvider.notifier);

    return AuthStepScaffold(
      title: 'Cette adresse\nest correcte ?',
      onBack: notifier.editEmail,
      errorMessage: state.errorMessage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                state.email,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            PressableScale(
              onTap: notifier.editEmail,
              child: Text(
                'Modifier',
                style: AppTypography.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      footer: PrimaryGradientButton(
        label: 'Continuer',
        onPressed: notifier.confirmEmailAndProceed,
      ),
    );
  }
}
