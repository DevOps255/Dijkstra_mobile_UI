import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pressable_scale.dart';

/// Élément de liste "trajet à suivre" — icône + nom + estimation,
/// reproduisant la géométrie exacte de la liste de destinations
/// récentes de la référence (Work / Cinema / Cafe + temps).
class RouteListTile extends StatelessWidget {
  const RouteListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.etaLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String etaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.primarySubtle, shape: BoxShape.circle),
              child: Icon(Icons.directions_bus_filled_rounded, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: AppTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(etaLabel, style: AppTypography.mono(size: 13, weight: FontWeight.w600, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
