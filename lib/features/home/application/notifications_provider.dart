import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../data/notifications_repository.dart';
import '../domain/notification_item.dart';

/// `autoDispose` — contrairement à `homeControllerProvider` (état
/// persistant de l'accueil), cette liste n'a besoin de vivre que
/// pendant que l'écran de notifications est ouvert. La quitter libère
/// la mémoire et garantit des données fraîches à la prochaine
/// ouverture plutôt qu'un cache silencieusement périmé.
final notificationsListProvider =
    FutureProvider.autoDispose<List<NotificationItem>>((ref) async {
  final repository = getIt<NotificationsRepository>();
  final result = await repository.fetch();
  return result.items;
});
