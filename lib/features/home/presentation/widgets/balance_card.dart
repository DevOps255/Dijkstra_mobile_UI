import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../application/home_controller.dart';

/// Zone de solde en haut de l'accueil — absente de la référence
/// visuelle, ajoutée explicitement à la demande. Repliée par défaut,
/// un tap révèle deux actions rapides (recharger / acheter).
class BalanceCard extends ConsumerStatefulWidget {
  const BalanceCard({
    super.key,
    required this.onRecharge,
    required this.onBuyTicket,
  });

  final VoidCallback onRecharge;
  final VoidCallback onBuyTicket;

  @override
  ConsumerState<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends ConsumerState<BalanceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(
      homeControllerProvider.select((s) => s.walletBalance),
    );

    return PressableScale(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
          boxShadow:  [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Solde disponible', style: AppTypography.label),
                      const SizedBox(height: 4),
                      Text(
                        '${balance.fcfa} FCFA',
                        style: AppTypography.mono(
                          size: 26,
                          weight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _MiniActionButton(
                              label: 'Recharger',
                              filled: false,
                              onTap: widget.onRecharge,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MiniActionButton(
                              label: 'Acheter un ticket',
                              filled: true,
                              onTap: widget.onBuyTicket,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: AppColors.divider),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.label.copyWith(
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
