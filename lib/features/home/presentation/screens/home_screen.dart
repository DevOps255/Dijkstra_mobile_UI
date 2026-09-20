import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/home_controller.dart';
import '../../domain/scheduled_departure.dart';
import '../widgets/balance_card.dart';
import '../widgets/date_scroll_picker.dart';
import '../widgets/direction_tabs.dart';
import '../widgets/home_bottom_nav_bar.dart';
import '../widgets/home_header.dart';
import '../widgets/live_map_preview_card.dart';
import '../widgets/stop_selector_card.dart';
import '../widgets/trip_list_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  HomeNavTab _currentTab = HomeNavTab.accueil;

  @override
  void initState() {
    super.initState();
    // Écoute la recommandation calculée par le contrôleur pour
    // afficher une popup non-bloquante — jamais dans build() pour
    // éviter de relancer une boîte de dialogue à chaque rebuild.
    Future.microtask(() {
      ref.listenManual<HomeState>(homeControllerProvider, (previous, next) {
        if (next.recommendationMessage != null &&
            next.recommendationMessage != previous?.recommendationMessage) {
          _showRecommendationDialog(next.recommendationMessage!);
        }
      });
    });
  }

  void _showRecommendationDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Conseil', style: AppTypography.headline),
          content: Text(message, style: AppTypography.bodyMedium),
          actions: [
            TextButton(
              onPressed: () {
                ref
                    .read(homeControllerProvider.notifier)
                    .dismissRecommendation();
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Compris',
                style: AppTypography.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleBuyTapped(ScheduledDeparture departure) {
    ref
        .read(homeControllerProvider.notifier)
        .evaluateRecommendation(departure.time);
    // L'achat effectif (débit portefeuille + création ticket, L34A)
    // est la prochaine étape du projet — placeholder honnête plutôt
    // qu'une fausse confirmation.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Achat du ticket ${departure.time} — bientôt disponible.'),
      ),
    );
  }

  void _handleNotificationsTap() {
    context.push('/home/notifications');
  }

  void _handleTabSelected(HomeNavTab tab) {
    if (tab == HomeNavTab.accueil) {
      setState(() => _currentTab = tab);
      return;
    }
    if (tab == HomeNavTab.portefeuille) {
      context.push('/home/wallet');
      return;
    }
    if (tab == HomeNavTab.tickets) {
      context.push('/home/tickets');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bientôt disponible.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            final notifier = ref.read(homeControllerProvider.notifier);
            await Future.wait([
              notifier.refreshWallet(),
              notifier.refreshNotifications(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              HomeHeader(
                studentId: state.currentUser?.id ?? '',
                fullName: state.currentUser?.fullName ?? '',
                unreadNotifications: state.unreadNotifications,
                onNotificationsTap: _handleNotificationsTap,
              ),
              const SizedBox(height: 24),
              BalanceCard(
                onRecharge: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recharge — bientôt disponible.'),
                    ),
                  );
                },
                onBuyTicket: () {},
              ),
              const SizedBox(height: 20),
              const DirectionTabs(),
              const SizedBox(height: 16),
              const StopSelectorCard(),
              const SizedBox(height: 20),
              const DateScrollPicker(),
              const SizedBox(height: 24),
              TripListSection(onBuyTapped: _handleBuyTapped),
              const SizedBox(height: 20),
              LiveMapPreviewCard(
                onOpenMap: () => _handleTabSelected(HomeNavTab.carte),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNavBar(
        currentTab: _currentTab,
        onTabSelected: _handleTabSelected,
      ),
    );
  }
}
