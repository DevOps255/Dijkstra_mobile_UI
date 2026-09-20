import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/wallet_transaction_item.dart';

class TransactionListTile extends StatelessWidget {
  const TransactionListTile({super.key, required this.transaction});
  final WalletTransactionItem transaction;

  bool get _isCredit => transaction.direction == WalletTransactionDirection.credit;

  String get _typeLabel {
    switch (transaction.type) {
      case WalletTransactionType.recharge: return 'Recharge';
      case WalletTransactionType.purchase: return 'Achat de ticket';
      case WalletTransactionType.refund: return 'Remboursement';
      case WalletTransactionType.unknown: return 'Transaction';
    }
  }

  String _relativeDate(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }

  @override
  Widget build(BuildContext context) {
    final color = _isCredit ? AppColors.success : AppColors.textPrimary;
    final sign = _isCredit ? '+' : '-';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36, alignment: Alignment.center,
            decoration: BoxDecoration(color: _isCredit ? AppColors.success.withOpacity(0.12) : AppColors.primarySubtle, shape: BoxShape.circle),
            child: Icon(_isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 16, color: _isCredit ? AppColors.success : AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description ?? _typeLabel, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(_relativeDate(transaction.createdAt), style: AppTypography.bodySmall),
              ],
            ),
          ),
          Text('$sign${transaction.amountFcfa} FCFA', style: AppTypography.mono(size: 14, weight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
