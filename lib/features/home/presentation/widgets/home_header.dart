import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_logo_mark.dart';
import '../../../../core/widgets/identicon_avatar.dart';
import '../../../../core/widgets/pressable_scale.dart';

/// En-tête de l'accueil.
///
/// Deux rangées, volontairement séparées :
/// 1. La marque — "Dijkstra" imposant, en haut à gauche, + la cloche
///    de notification (ouvre une interface à part entière, jamais un
///    tiroir superficiel — voir `onNotificationsTap`).
/// 2. La salutation personnelle — avatar + prénom, secondaire par
///    rapport à la marque, cohérent avec le registre WhatsApp/Netflix
///    où le nom de l'app prime visuellement sur le contenu utilisateur.
///
/// [fullName] provient de `AuthUser.fullName` (saisi à l'inscription,
/// module auth) — jamais un texte générique codé en dur.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.studentId,
    required this.fullName,
    required this.unreadNotifications,
    required this.onNotificationsTap,
  });

  final String studentId;
  final String fullName;
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;

  String get _firstName {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Étudiant';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppWordmark(logoSize: 34),
            const Spacer(),
            PressableScale(
              onTap: onNotificationsTap,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (unreadNotifications > 0)
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            IdenticonAvatar(seed: studentId, size: 36),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour', style: AppTypography.label),
                Text(
                  _firstName,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
