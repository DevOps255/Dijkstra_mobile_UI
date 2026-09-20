import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_logo_mark.dart';
import '../../application/recharge_flow_controller.dart';
import '../../application/wallet_controller.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/recharge_flow_sheet.dart';
import '../widgets/transaction_list_tile.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  void _openRechargeSheet(BuildContext context, WidgetRef ref) {
    ref.read(rechargeFlowControllerProvider.notifier).reset();
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const RechargeFlowSheet(),
    ).whenComplete(() {
      ref.read(walletControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletControllerProvider);
    final notifier = ref.read(walletControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: notifier.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const AppWordmark(logoSize: 30),
              const SizedBox(height: 20),
              BalanceHeroCard(balance: state.balance, isLoading: state.isLoadingBalance),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _openRechargeSheet(context, ref),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text('Recharger', style: AppTypography.button.copyWith(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 28),
              Text('Historique', style: AppTypography.headline),
              const SizedBox(height: 14),
              if (state.isLoadingTransactions)
                const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary))))
              else if (state.transactions.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: Text('Aucune transaction pour le moment.', style: AppTypography.bodyMedium))
              else
                ...state.transactions.map((t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TransactionListTile(transaction: t))),
            ],
          ),
        ),
      ),
    );
  }
}
