import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/ticket_repository.dart';
import '../../domain/ticket_totp_code.dart';

/// Secours de dernier recours — le code TOTP est affiché en clair
/// uniquement dans cet écran, sur demande explicite (appui pour
/// révéler) et masqué automatiquement après 10 secondes. Jamais
/// affiché ailleurs dans l'app.
class ManualFallbackView extends StatefulWidget {
  const ManualFallbackView({super.key, required this.ticketId, required this.onBack});

  final String ticketId;
  final VoidCallback onBack;

  @override
  State<ManualFallbackView> createState() => _ManualFallbackViewState();
}

class _ManualFallbackViewState extends State<ManualFallbackView> {
  TicketTotpCode? _current;
  bool _revealed = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    getIt<TicketRepository>().fetchTotpCode(widget.ticketId).then((code) {
      if (mounted) setState(() => _current = code);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _reveal() {
    setState(() => _revealed = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _revealed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shortId = widget.ticketId.length >= 8 ? widget.ticketId.substring(0, 8) : widget.ticketId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Saisie manuelle', style: AppTypography.headline),
        const SizedBox(height: 8),
        Text('Donnez ce numéro au chauffeur :', style: AppTypography.bodyMedium),
        const SizedBox(height: 12),
        Text(shortId.toUpperCase(),
            style: AppTypography.mono(size: 28, weight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 20),
        Text('Le chauffeur saisira aussi votre code à 6 chiffres.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        if (_current == null)
          const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_revealed)
          Text(_current!.code6Digits,
              style: AppTypography.mono(size: 32, weight: FontWeight.w700, color: AppColors.primary))
        else
          TextButton(onPressed: _reveal, child: const Text('Afficher le code (10s)')),
        const SizedBox(height: 20),
        TextButton(onPressed: widget.onBack, child: const Text('← Retour à l\'ultrason')),
      ],
    );
  }
}
