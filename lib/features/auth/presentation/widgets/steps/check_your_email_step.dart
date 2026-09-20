import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/pressable_scale.dart';
import '../../../../../core/widgets/primary_gradient_button.dart';
import '../../../application/auth_flow_controller.dart';
import '../auth_step_scaffold.dart';

class CheckYourEmailStep extends ConsumerStatefulWidget {
  const CheckYourEmailStep({super.key});

  @override
  ConsumerState<CheckYourEmailStep> createState() =>
      _CheckYourEmailStepState();
}

class _CheckYourEmailStepState extends ConsumerState<CheckYourEmailStep> {
  bool _mailAppOpenAttempted = false;

  Future<void> _openMailApp() async {
    setState(() => _mailAppOpenAttempted = true);
    final opened =
        await ref.read(authFlowControllerProvider.notifier).openMailApp();
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ouvrez votre application mail manuellement.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowControllerProvider);

    return AuthStepScaffold(
      title: 'Vérifiez votre\nboîte mail.',
      subtitle:
          'Un lien de confirmation a été envoyé à ${state.email}. '
          'Cliquez dessus pour finaliser votre inscription.',
      errorMessage: state.errorMessage,
      infoMessage: state.infoMessage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.isLoading)
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Confirmation en cours...',
                  style: AppTypography.bodyMedium,
                ),
              ],
            )
          else if (_mailAppOpenAttempted)
            Text(
              'En attente de votre confirmation par email.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryGradientButton(
            label: 'Ouvrir ma messagerie',
            onPressed: _openMailApp,
          ),
          const SizedBox(height: 16),
          PressableScale(
            onTap: state.isLoading
                ? null
                : () => ref
                    .read(authFlowControllerProvider.notifier)
                    .resendVerificationEmail(),
            child: Text(
              'Je n\'ai rien reçu — renvoyer l\'email',
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
