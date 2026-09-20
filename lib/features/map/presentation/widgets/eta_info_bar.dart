import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/eta_estimate.dart';

/// Bandeau d'information en bas de carte — reproduit la carte
/// "9,7 km / 29 min" de la référence : distance + temps, avec un
/// état "approche imminente" mis en évidence.
class EtaInfoBar extends StatelessWidget {
  const EtaInfoBar({super.key, required this.eta, required this.lastMessage});

  final EtaEstimate? eta;
  final String? lastMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastMessage != null) ...[
            Text(lastMessage!, style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
          ],
          if (eta == null)
            Text('En attente de la position du bus...', style: AppTypography.bodyMedium)
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricColumn(
                  label: 'Distance',
                  value: eta!.distanceMeters >= 1000
                      ? '${(eta!.distanceMeters / 1000).toStringAsFixed(1)} km'
                      : '${eta!.distanceMeters} m',
                ),
                _MetricColumn(
                  label: 'Arrivée estimée',
                  value: eta!.estimatedMinutes != null ? '${eta!.estimatedMinutes} min' : '—',
                  highlight: eta!.isApproaching,
                ),
              ],
            ),
            if (eta!.isApproaching) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text('🚌 Le bus approche', style: AppTypography.bodyMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.mono(size: 20, weight: FontWeight.w700, color: highlight ? AppColors.success : AppColors.textPrimary)),
      ],
    );
  }
}
