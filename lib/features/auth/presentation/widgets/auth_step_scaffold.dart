import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_logo_mark.dart';
import '../../../../core/widgets/pressable_scale.dart';

/// Structure commune à chaque étape du flux d'authentification.
///
/// Garantit une cohérence stricte : même position de titre, même
/// espacement, même ancrage du bouton principal en bas d'écran, quel
/// que soit le clavier ouvert ou non (via `SingleChildScrollView` +
/// `resizeToAvoidBottomInset`).
class AuthStepScaffold extends StatelessWidget {
  const AuthStepScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onBack,
    this.footer,
    this.errorMessage,
    this.infoMessage,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? footer;
  final String? errorMessage;
  final String? infoMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: AppWordmark(logoSize: 28),
            ),
            if (onBack != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: PressableScale(
                  onTap: onBack,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('Retour', style: AppTypography.label),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: onBack != null ? 12 : 32),
                    Text(title, style: AppTypography.displayMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        subtitle!,
                        style: AppTypography.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: 32),
                    child,
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: errorMessage!),
                    ],
                    if (infoMessage != null) ...[
                      const SizedBox(height: 16),
                      _InfoBanner(message: infoMessage!),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.35)),
      ),
      child: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.35)),
      ),
      child: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.success),
      ),
    );
  }
}
