import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animation/app_spring.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ticket.dart';
import '../widgets/manual_fallback_view.dart';
import '../widgets/qr_fallback_view.dart';
import '../widgets/ultrasound_validation_view.dart';

enum _DetailPane { ultrasound, qr, manual }

class TicketDetailScreen extends ConsumerStatefulWidget {
  const TicketDetailScreen({super.key, required this.ticket});

  final Ticket ticket;

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  _DetailPane _pane = _DetailPane.ultrasound;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(widget.ticket.lineName, style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: const SpringCurve(response: 0.34),
                switchOutCurve: const SpringCurve(response: 0.34),
                child: KeyedSubtree(
                  key: ValueKey(_pane),
                  child: switch (_pane) {
                    _DetailPane.ultrasound => UltrasoundValidationView(
                        ticketId: widget.ticket.id,
                        tripId: widget.ticket.tripId,
                        onShowQrFallback: () => setState(() => _pane = _DetailPane.qr),
                        onShowManualFallback: () => setState(() => _pane = _DetailPane.manual),
                      ),
                    _DetailPane.qr => QrFallbackView(
                        ticketId: widget.ticket.id,
                        onBack: () => setState(() => _pane = _DetailPane.ultrasound),
                      ),
                    _DetailPane.manual => ManualFallbackView(
                        ticketId: widget.ticket.id,
                        onBack: () => setState(() => _pane = _DetailPane.ultrasound),
                      ),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
