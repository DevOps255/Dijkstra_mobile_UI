import 'package:flutter/material.dart';

import '../../../../core/mobile_money/mobile_money_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pressable_scale.dart';

class OperatorPickerCard extends StatelessWidget {
  const OperatorPickerCard({super.key, required this.operator, required this.onTap});
  final MobileOperator operator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final config = MobileMoneyConfig.operators[operator]!;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: config.brandColor.withOpacity(0.35))),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Image.asset(
                config.logoAsset, fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(config.displayName, style: AppTypography.bodyLarge.copyWith(color: config.brandColor, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(config.displayName, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
