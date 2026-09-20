import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_logo_mark.dart';
import '../../application/ticket_list_controller.dart';
import '../widgets/staggered_entrance.dart';
import '../widgets/ticket_card.dart';
import 'ticket_detail_screen.dart';

class TicketsListScreen extends ConsumerWidget {
  const TicketsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ticketListControllerProvider);
    final notifier = ref.read(ticketListControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: notifier.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const AppWordmark(logoSize: 30),
              const SizedBox(height: 20),
              Text('Mes tickets', style: AppTypography.headline),
              const SizedBox(height: 16),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary))),
                )
              else if (state.tickets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text('Aucun ticket pour le moment.', style: AppTypography.bodyMedium),
                )
              else
                ...state.tickets.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: StaggeredEntrance(
                        index: entry.key,
                        child: TicketCard(
                          ticket: entry.value,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: entry.value)),
                          ),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
