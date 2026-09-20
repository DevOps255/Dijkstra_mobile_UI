import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/wallet_balance.dart';

class BalanceHeroCard extends StatelessWidget {
  const BalanceHeroCard({super.key, required this.balance, required this.isLoading});

  final WalletBalance balance;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryButtonGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Solde disponible', style: AppTypography.label.copyWith(color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 8),
          isLoading
              ? const SizedBox(
                  height: 40, width: 40,
                  child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)),
                )
              : Text('${balance.fcfa} FCFA', style: AppTypography.mono(size: 36, weight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}
