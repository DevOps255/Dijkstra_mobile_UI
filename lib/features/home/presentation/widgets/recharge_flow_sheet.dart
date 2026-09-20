import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animation/app_spring.dart';
import '../../../../core/mobile_money/mobile_money_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../../wallet/application/recharge_flow_controller.dart';
import 'operator_picker_card.dart';

class RechargeFlowSheet extends ConsumerStatefulWidget {
  const RechargeFlowSheet({super.key});
  @override
  ConsumerState<RechargeFlowSheet> createState() => _RechargeFlowSheetState();
}

class _RechargeFlowSheetState extends ConsumerState<RechargeFlowSheet> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rechargeFlowControllerProvider);
    final notifier = ref.read(rechargeFlowControllerProvider.notifier);

    ref.listen<RechargeFlowState>(rechargeFlowControllerProvider, (previous, next) {
      if (next.step == RechargeStep.success) {
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: const SpringCurve(),
        switchOutCurve: const SpringCurve(),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation), child: child),
        ),
        child: KeyedSubtree(key: ValueKey<RechargeStep>(state.step), child: _buildStep(context, state, notifier)),
      ),
    );
  }

  Widget _buildStep(BuildContext context, RechargeFlowState state, RechargeFlowController notifier) {
    switch (state.step) {
      case RechargeStep.selectOperator:
        return _OperatorStep(notifier: notifier);
      case RechargeStep.enterAmount:
        return _AmountStep(controller: _amountController, state: state, notifier: notifier);
      case RechargeStep.requestingPermission:
        return const _StatusStep(message: 'Vérification des permissions...', showSpinner: true);
      case RechargeStep.permissionDenied:
        return _RetryStep(message: state.errorMessage ?? 'Permissions refusées.', buttonLabel: 'Autoriser', onRetry: () => notifier.startRecharge(state.amountFcfa ?? 0));
      case RechargeStep.permissionPermanentlyDenied:
        return _RetryStep(message: state.errorMessage ?? 'Permissions bloquées.', buttonLabel: 'Ouvrir les réglages', onRetry: notifier.openSystemSettings);
      case RechargeStep.selectSim:
        return _SimStep(state: state, notifier: notifier);
      case RechargeStep.dialing:
        return const _StatusStep(message: 'Composition en cours...', showSpinner: true);
      case RechargeStep.waitingForSms:
        return const _StatusStep(message: 'En attente de confirmation...\nEntrez votre code Mobile Money sur l\'écran qui s\'est ouvert.', showSpinner: true);
      case RechargeStep.submitting:
        return const _StatusStep(message: 'Validation en cours...', showSpinner: true);
      case RechargeStep.success:
        return _SuccessStep(state: state);
      case RechargeStep.failed:
        return _RetryStep(message: state.errorMessage ?? 'La recharge a échoué.', buttonLabel: 'Réessayer', onRetry: notifier.reset);
    }
  }
}

class _OperatorStep extends StatelessWidget {
  const _OperatorStep({required this.notifier});
  final RechargeFlowController notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choisissez votre opérateur', style: AppTypography.headline),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: OperatorPickerCard(operator: MobileOperator.mixx, onTap: () => notifier.selectOperator(MobileOperator.mixx))),
            const SizedBox(width: 14),
            Expanded(child: OperatorPickerCard(operator: MobileOperator.flooz, onTap: () => notifier.selectOperator(MobileOperator.flooz))),
          ],
        ),
      ],
    );
  }
}

class _AmountStep extends StatelessWidget {
  const _AmountStep({required this.controller, required this.state, required this.notifier});
  final TextEditingController controller;
  final RechargeFlowState state;
  final RechargeFlowController notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Montant à recharger', style: AppTypography.headline),
        const SizedBox(height: 6),
        Text('Minimum ${MobileMoneyConfig.minimumRechargeFcfa} FCFA.', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 18),
        TextField(
          controller: controller, keyboardType: TextInputType.number, autofocus: true,
          style: AppTypography.mono(size: 24, weight: FontWeight.w600),
          decoration: const InputDecoration(suffixText: 'FCFA', hintText: '0'),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(state.errorMessage!, style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
        ],
        const SizedBox(height: 16),
        PrimaryGradientButton(
          label: 'Recharger',
          onPressed: () {
            final amount = int.tryParse(controller.text.trim()) ?? 0;
            notifier.startRecharge(amount);
          },
        ),
      ],
    );
  }
}

class _SimStep extends StatelessWidget {
  const _SimStep({required this.state, required this.notifier});
  final RechargeFlowState state;
  final RechargeFlowController notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quelle carte SIM ?', style: AppTypography.headline),
        const SizedBox(height: 6),
        Text('Choisissez la carte associée à votre compte Mobile Money.', style: AppTypography.bodyMedium),
        const SizedBox(height: 18),
        ...state.availableSims.map((sim) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PressableScale(
                onTap: () => notifier.selectSim(sim),
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                  child: Row(
                    children: [
                      Icon(Icons.sim_card_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(sim.carrierName.isNotEmpty ? sim.carrierName : sim.displayName, style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({required this.message, required this.showSpinner});
  final String message;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        if (showSpinner) const CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
        const SizedBox(height: 20),
        Text(message, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _RetryStep extends StatelessWidget {
  const _RetryStep({required this.message, required this.buttonLabel, required this.onRetry});
  final String message;
  final String buttonLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 32),
        const SizedBox(height: 14),
        Text(message, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
        const SizedBox(height: 18),
        PrimaryGradientButton(label: buttonLabel, onPressed: onRetry),
      ],
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({required this.state});
  final RechargeFlowState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
        const SizedBox(height: 14),
        Text('+${state.amountCreditedFcfa} FCFA', style: AppTypography.mono(size: 24, weight: FontWeight.w700, color: AppColors.success)),
        const SizedBox(height: 4),
        Text('Nouveau solde : ${state.newBalanceFcfa} FCFA', style: AppTypography.bodyMedium),
        const SizedBox(height: 20),
      ],
    );
  }
}
