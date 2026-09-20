import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pressable_scale.dart';

/// Champ de recherche visuel — reproduit fidèlement l'affordance
/// "Où allons-nous ?" de la référence, mais ici les destinations
/// sont fixes (deux campus) : le tap ouvre le sélecteur de trajet
/// plutôt qu'un clavier, ce qui reste honnête sur ce que l'app
/// peut réellement faire.
class RouteSearchField extends StatelessWidget {
  const RouteSearchField({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 20),
            const SizedBox(width: 10),
            Text('Où allez-vous ?', style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
