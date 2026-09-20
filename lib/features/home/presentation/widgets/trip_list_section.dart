import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../application/home_controller.dart';
import '../../domain/scheduled_departure.dart';
import 'trip_card.dart';

class TripListSection extends ConsumerStatefulWidget {
  const TripListSection({super.key, required this.onBuyTapped});

  final void Function(ScheduledDeparture departure) onBuyTapped;

  @override
  ConsumerState<TripListSection> createState() => _TripListSectionState();
}

class _TripListSectionState extends ConsumerState<TripListSection> {
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);

    final departures = [...state.departures]
      ..sort((a, b) => _ascending
          ? a.time.compareTo(b.time)
          : b.time.compareTo(a.time));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Départs disponibles', style: AppTypography.headline),
            PressableScale(
              onTap: () => setState(() => _ascending = !_ascending),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _ascending
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text('Heure', style: AppTypography.label),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (state.isLoadingDepartures)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          )
        else if (departures.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Aucun départ disponible pour cet arrêt à cette date.',
              style: AppTypography.bodyMedium,
            ),
          )
        else
          ...departures.map(
            (departure) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TripCard(
                departure: departure,
                onBuyTapped: () => widget.onBuyTapped(departure),
              ),
            ),
          ),
      ],
    );
  }
}
