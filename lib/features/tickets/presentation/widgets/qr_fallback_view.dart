import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/ticket_repository.dart';
import '../../domain/ticket_totp_code.dart';

/// Secours secondaire — atteint uniquement via le lien discret
/// "Problème avec le son ?" de la vue ultrason. Le code affiché est
/// celui déjà signé par le serveur (jamais calculé ici) ; il se
/// rafraîchit automatiquement avant expiration.
class QrFallbackView extends StatefulWidget {
  const QrFallbackView({super.key, required this.ticketId, required this.onBack});

  final String ticketId;
  final VoidCallback onBack;

  @override
  State<QrFallbackView> createState() => _QrFallbackViewState();
}

class _QrFallbackViewState extends State<QrFallbackView> {
  late final TicketRepository _repository;
  Timer? _refreshTimer;
  TicketTotpCode? _current;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = getIt<TicketRepository>();
    _load();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final code = await _repository.fetchTotpCode(widget.ticketId);
      if (!mounted) return;
      setState(() { _current = code; _isLoading = false; });

      _refreshTimer?.cancel();
      final refreshIn = Duration(seconds: (code.secondsRemaining - 5).clamp(1, 300));
      _refreshTimer = Timer(refreshIn, _load);
    } catch (error) {
      if (!mounted) return;
      setState(() { _isLoading = false; _error = 'Impossible de générer le QR code.'; });
    }
  }

  String get _qrPayload {
    final code = _current!;
    final sigHex = code.qrSignatureBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return jsonEncode({
      'tid': widget.ticketId,
      'code': code.code6Digits,
      'ts': code.validFromUnix,
      'sig': sigHex,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Montrez ce QR au chauffeur', style: AppTypography.headline),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: _isLoading
              ? const SizedBox(
                  key: ValueKey('qr-loading'),
                  height: 220, child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)))
              : _error != null
                  ? SizedBox(
                      key: const ValueKey('qr-error'),
                      height: 220,
                      child: Center(child: Text(_error!, style: AppTypography.bodyMedium.copyWith(color: AppColors.danger))),
                    )
                  : Container(
                      key: const ValueKey('qr-ready'),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: QrImageView(
                        data: _qrPayload,
                        size: 220,
                        backgroundColor: Colors.white,
                      ),
                    ),
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: widget.onBack, child: const Text('← Retour à l\'ultrason')),
      ],
    );
  }
}
