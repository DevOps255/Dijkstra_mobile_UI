import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_logo_mark.dart';
import '../../../tickets/application/ticket_list_controller.dart';
import '../../../tickets/domain/ticket.dart';
import '../widgets/route_list_tile.dart';
import '../widgets/route_search_field.dart';
import 'live_tracking_screen.dart';

/// Écran d'accueil de l'onglet Carte — reproduit la structure de la
/// référence (barre de recherche + liste de destinations récentes),
/// adaptée au domaine réel : les "destinations" sont les trajets
/// pour lesquels l'étudiant a un ticket actif, seuls trajets que le
/// serveur autorise à suivre en temps réel (contrat WebSocket L37A).
class MapHomeScreen extends ConsumerWidget {
  const MapHomeScreen({super.key});

  List<Ticket> _trackableTickets(List<Ticket> tickets) {
    return tickets.where((t) => t.isValid && t.lineId.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketState = ref.watch(ticketListControllerProvider);
    final trackable = _trackableTickets(ticketState.tickets);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const AppWordmark(logoSize: 30),
            const SizedBox(height: 20),
            RouteSearchField(onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Choisissez un trajet dans la liste ci-dessous.')),
              );
            }),
            const SizedBox(height: 24),
            Text('Vos trajets', style: AppTypography.headline),
            const SizedBox(height: 4),
            Text(
              'Suivi en temps réel disponible pour les trajets avec un ticket actif.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 12),
            if (ticketState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary))),
              )
            else if (trackable.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text('Aucun trajet à suivre pour le moment. Achetez un ticket pour activer le suivi.',
                    style: AppTypography.bodyMedium),
              )
            else
              ...trackable.map((ticket) => RouteListTile(
                    title: ticket.lineName,
                    subtitle: '${ticket.boardingStopName} → ${ticket.alightingStopName}',
                    etaLabel: 'Suivre',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => LiveTrackingScreen(ticket: ticket)),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
