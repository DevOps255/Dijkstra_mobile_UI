import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/animation/app_spring.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../application/ticket_validation_controller.dart';
import '../../domain/validation_outcome.dart';

const _stateTransitionDuration = Duration(milliseconds: 280);

/// Vue de validation PRINCIPALE — l'ultrason est le mécanisme mis
/// en avant, pas un repli. Fonctionne en plein soleil et à l'ombre,
/// là où un scan QR devient peu fiable (contrainte terrain explicite,
/// pas une préférence esthétique).
class UltrasoundValidationView extends ConsumerWidget {
  const UltrasoundValidationView({
    super.key,
    required this.ticketId,
    required this.tripId,
    required this.onShowQrFallback,
    required this.onShowManualFallback,
  });

  final String ticketId;
  final String tripId;
  final VoidCallback onShowQrFallback;
  final VoidCallback onShowManualFallback;

  Future<void> _startValidation(BuildContext context, WidgetRef ref) async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission microphone requise pour valider par ultrason.')),
        );
      }
      return;
    }

    await ref.read(ticketValidationControllerProvider.notifier).startUltrasonicValidation(
          ticketId: ticketId,
          expectedTripId: tripId,
        );
  }

  bool _isErrorOutcome(ValidationOutcome outcome) {
    return outcome == ValidationOutcome.wrongBus ||
        outcome == ValidationOutcome.beaconExpired ||
        outcome == ValidationOutcome.timeout ||
        outcome == ValidationOutcome.failed ||
        outcome == ValidationOutcome.error;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ticketValidationControllerProvider);
    final notifier = ref.read(ticketValidationControllerProvider.notifier);

    // Retour haptique — la confirmation doit être perceptible même
    // dans un bus bruyant ou en plein soleil où l'écran est peu
    // lisible (principe de retour multimodal : le signal doit
    // arriver sur le même événement causal, ici la transition
    // d'état elle-même, jamais différé).
    ref.listen<TicketValidationState>(ticketValidationControllerProvider, (previous, next) {
      if (previous?.outcome != next.outcome) {
        if (next.outcome == ValidationOutcome.success) {
          HapticFeedback.mediumImpact();
        } else if (_isErrorOutcome(next.outcome) &&
            previous?.outcome != ValidationOutcome.idle) {
          HapticFeedback.lightImpact();
        }
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: _stateTransitionDuration,
          switchInCurve: const SpringCurve(response: 0.32),
          switchOutCurve: const SpringCurve(response: 0.32),
          transitionBuilder: (child, animation) {
            // Jamais d'apparition depuis scale(0) — rien dans le
            // monde réel n'apparaît de rien. On part de 0.95, pas 0.
            final scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: scaleAnim, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(state.outcome),
            child: _buildContent(context, ref, state, notifier),
          ),
        ),
        const SizedBox(height: 28),
        AnimatedSwitcher(
          duration: _stateTransitionDuration,
          switchInCurve: const SpringCurve(response: 0.32),
          switchOutCurve: const SpringCurve(response: 0.32),
          child: (state.outcome == ValidationOutcome.idle || state.outcome == ValidationOutcome.failed)
              ? Column(
                  key: const ValueKey('fallback-links'),
                  children: [
                    TextButton(
                      onPressed: onShowQrFallback,
                      child: Text('Problème avec le son ? QR Code',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                    ),
                    TextButton(
                      onPressed: onShowManualFallback,
                      child: Text('Saisie manuelle',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                    ),
                  ],
                )
              : const SizedBox.shrink(key: ValueKey('fallback-links-hidden')),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    TicketValidationState state,
    TicketValidationController notifier,
  ) {
    switch (state.outcome) {
      case ValidationOutcome.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq_rounded, size: 64, color: AppColors.primary),
            const SizedBox(height: 20),
            Text('Approchez votre téléphone du haut-parleur du bus',
                textAlign: TextAlign.center, style: AppTypography.bodyMedium),
            const SizedBox(height: 24),
            PrimaryGradientButton(
              label: 'Valider mon ticket',
              onPressed: () => _startValidation(context, ref),
            ),
          ],
        );

      case ValidationOutcome.listening:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PulsingMicIcon(),
            const SizedBox(height: 20),
            Text('Écoute en cours...', style: AppTypography.headline),
            const SizedBox(height: 6),
            Text('Approchez votre téléphone du haut-parleur du bus',
                textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
          ],
        );

      case ValidationOutcome.fetchingCode:
      case ValidationOutcome.submitting:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
            SizedBox(height: 16),
            Text('Validation en cours...'),
          ],
        );

      case ValidationOutcome.success:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
            const SizedBox(height: 14),
            Text('Ticket validé !', style: AppTypography.headline),
            Text('Bon trajet.', style: AppTypography.bodyMedium),
          ],
        );

      case ValidationOutcome.wrongBus:
      case ValidationOutcome.beaconExpired:
      case ValidationOutcome.timeout:
      case ValidationOutcome.failed:
      case ValidationOutcome.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
            const SizedBox(height: 12),
            Text(
              state.errorMessage ?? 'Erreur de validation.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 18),
            PrimaryGradientButton(label: 'Réessayer', onPressed: notifier.reset),
          ],
        );
    }
  }
}

class _PulsingMicIcon extends StatefulWidget {
  const _PulsingMicIcon();
  @override
  State<_PulsingMicIcon> createState() => _PulsingMicIconState();
}

class _PulsingMicIconState extends State<_PulsingMicIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Pulsation continue, non déclenchée par un geste — une courbe
    // ease-in-out en boucle reste appropriée ici (contrairement aux
    // transitions d'état ci-dessus) : ce n'est ni interruptible ni
    // porteur de vélocité, juste un indicateur ambiant.
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.9, end: 1.15).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Icon(Icons.mic_rounded, size: 64, color: AppColors.primary),
    );
  }
}
