import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../application/home_controller.dart';

const List<String> _kFrenchMonthAbbreviations = [
  'Jan',
  'Fév',
  'Mar',
  'Avr',
  'Mai',
  'Juin',
  'Juil',
  'Août',
  'Sep',
  'Oct',
  'Nov',
  'Déc',
];

/// Sélecteur de date de trajet — 7 prochains jours. Le son (demandé
/// explicitement : grincement mécanique bref, cf. `SoundService`) se
/// joue à chaque changement de jour sélectionné, pas à chaque défilement
/// brut de la liste — évite un bruit continu désagréable pendant un
/// scroll rapide.
class DateScrollPicker extends ConsumerWidget {
  const DateScrollPicker({super.key});

  static const int _daysAhead = 7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(
      homeControllerProvider.select((s) => s.selectedDate),
    );
    final notifier = ref.read(homeControllerProvider.notifier);
    final today = DateTime.now();
    final baseDate = DateTime(today.year, today.month, today.day);

    final days = List.generate(
      _daysAhead,
      (index) => baseDate.add(Duration(days: index)),
    );

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _isSameDay(day, selectedDate);

          return _DayChip(
            day: day,
            selected: isSelected,
            onTap: () {
              if (!isSelected) {
                getIt<SoundService>().playDateScrollTick();
              }
              notifier.setSelectedDate(day);
            },
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayNumber = day.day.toString();
    final monthLabel = _kFrenchMonthAbbreviations[day.month - 1];

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 48,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNumber,
              style: AppTypography.mono(
                size: 17,
                weight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              monthLabel,
              style: AppTypography.bodySmall.copyWith(
                color: selected
                    ? Colors.white.withOpacity(0.85)
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
