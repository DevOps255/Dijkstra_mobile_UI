import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../application/home_controller.dart';
import '../../domain/campus_route.dart';

/// Carte "Point de montée / Destination" — équivalent fonctionnel du
/// bloc From/To de la référence. Le bouton d'inversion (même
/// position, même icône que la référence) bascule le sens Aller/Retour
/// plutôt que d'échanger deux champs libres : ça reste la même
/// affordance ("inverser mon trajet"), appliquée à un système où la
/// destination est déterminée par le sens, pas saisie librement.
class StopSelectorCard extends ConsumerWidget {
  const StopSelectorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final notifier = ref.read(homeControllerProvider.notifier);
    final destination = CampusRoute.destinationFor(state.direction);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _StopRow(
                dotColor: AppColors.primary,
                label: 'Point de montée',
                value: state.boardingStop.name,
                onTap: () => _openStopPicker(context, ref, state),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const SizedBox(width: 5),
                    Expanded(
                      child: Container(height: 1, color: AppColors.divider),
                    ),
                  ],
                ),
              ),
              _StopRow(
                dotColor: AppColors.textTertiary,
                label: 'Destination',
                value: destination,
                onTap: null,
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: PressableScale(
                onTap: () => notifier.setDirection(
                  state.direction == TripDirection.aller
                      ? TripDirection.retour
                      : TripDirection.aller,
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Icon(
                    Icons.swap_vert_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openStopPicker(
    BuildContext context,
    WidgetRef ref,
    HomeState state,
  ) {
    // Tous les arrêts sauf le terminus (on ne "monte" pas au terminus
    // — on y descend).
    final allStops = CampusRoute.stopsFor(state.direction);
    final boardableStops = allStops.sublist(0, allStops.length - 1);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choisir un point de montée',
                  style: AppTypography.headline,
                ),
                const SizedBox(height: 16),
                ...boardableStops.map(
                  (stop) => _StopPickerTile(
                    stop: stop,
                    selected: stop.id == state.boardingStop.id,
                    onTap: () {
                      ref
                          .read(homeControllerProvider.notifier)
                          .setBoardingStop(stop);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.dotColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final Color dotColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 40), // réserve l'espace du bouton swap
      ],
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

class _StopPickerTile extends StatelessWidget {
  const _StopPickerTile({
    required this.stop,
    required this.selected,
    required this.onTap,
  });

  final CampusStop stop;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primarySubtle : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                stop.name,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (stop.branchNote != null)
              Flexible(
                flex: 2,
                child: Text(
                  stop.branchNote!,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
