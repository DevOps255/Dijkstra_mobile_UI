import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

enum HomeNavTab { accueil, tickets, portefeuille, carte, profil }

class _NavItem {
  const _NavItem(this.tab, this.icon, this.outline, this.label);
  final HomeNavTab tab;
  final IconData icon;
  final IconData outline;
  final String label;
}

/// Ordre demandé : Tickets et Portefeuille avant Carte — usage plus
/// fréquent que la carte au quotidien. Labels ajoutés sous chaque
/// icône (auparavant icône seule).
class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final HomeNavTab currentTab;
  final void Function(HomeNavTab tab) onTabSelected;

  static const List<_NavItem> _items = [
    _NavItem(HomeNavTab.accueil, Icons.home_rounded, Icons.home_outlined, 'Accueil'),
    _NavItem(
      HomeNavTab.tickets,
      Icons.confirmation_number_rounded,
      Icons.confirmation_number_outlined,
      'Tickets',
    ),
    _NavItem(
      HomeNavTab.portefeuille,
      Icons.account_balance_wallet_rounded,
      Icons.account_balance_wallet_outlined,
      'Portefeuille',
    ),
    _NavItem(HomeNavTab.carte, Icons.map_rounded, Icons.map_outlined, 'Carte'),
    _NavItem(
      HomeNavTab.profil,
      Icons.person_rounded,
      Icons.person_outline_rounded,
      'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _items.map((item) {
            final selected = item.tab == currentTab;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTabSelected(item.tab),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? item.icon : item.outline,
                      size: 23,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10.5,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
