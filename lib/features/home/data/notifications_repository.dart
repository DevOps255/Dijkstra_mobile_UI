import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../domain/notification_item.dart';

/// ADDENDUM BACKEND REQUIS — absent de L22/L33-L42.
///
/// Endpoint attendu : `GET /notifications?unread_only=false`
/// Réponse attendue : `{"items": [...], "unread_count": int}`
///
/// Sources plausibles de notifications déjà présentes côté backend
/// (à agréger dans une table `notifications` dédiée, ou à défaut
/// exposer en lecture directe) :
/// - `wallet_recharged` (L34A, déjà poussé en WebSocket — juste
///   besoin d'une persistance + endpoint de lecture)
/// - `affluence_alert` (L38A, déjà publié en Redis pub/sub côté
///   chauffeur — variante étudiant à créer)
/// - `stop_cleared` / retardataires (L38B)
///
/// En attendant, dégradation propre : liste vide, compteur à 0,
/// jamais d'erreur visible.
@lazySingleton
class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  Future<({List<NotificationItem> items, int unreadCount})> fetch() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notifications',
      );
      final data = response.data;
      if (data == null) return (items: <NotificationItem>[], unreadCount: 0);

      final rawItems = data['items'] as List<dynamic>? ?? [];
      final items = rawItems
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final unreadCount = data['unread_count'] as int? ?? 0;

      return (items: items, unreadCount: unreadCount);
    } on DioException {
      return (items: <NotificationItem>[], unreadCount: 0);
    }
  }
}
