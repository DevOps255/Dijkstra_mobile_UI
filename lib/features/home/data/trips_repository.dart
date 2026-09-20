import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

/// ADDENDUM BACKEND REQUIS — absent de L33/L34A sous cette forme.
///
/// Le schéma `Trip` (L33) existe déjà (`scheduled_departure`,
/// `available_seats`, `line_id`) mais aucun endpoint ne permet de
/// lister les trajets d'une date donnée filtrés par sens de
/// circulation. Endpoint attendu :
///
/// `GET /trips?date=2026-08-06&direction=aller`
/// Réponse : `[{"trip_id": "...", "departure_time": "05:30",
///              "available_seats": 41, "fare_amount": 15000}, ...]`
///
/// Tant que cet endpoint n'existe pas, [fetchLiveTrips] retourne une
/// map vide et l'accueil affiche l'horaire déterministe
/// ([CampusSchedule]) avec l'achat désactivé — jamais de données
/// inventées présentées comme réelles.
@lazySingleton
class TripsRepository {
  TripsRepository(this._dio);

  final Dio _dio;

  /// Retourne une map `heure de départ -> (tripId, placesRestantes)`.
  Future<Map<String, ({String tripId, int availableSeats})>>
      fetchLiveTrips({
    required DateTime date,
    required String direction,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/trips',
        queryParameters: {
          'date': _formatDate(date),
          'direction': direction,
        },
      );

      final raw = response.data ?? [];
      final result = <String, ({String tripId, int availableSeats})>{};

      for (final entry in raw) {
        final map = entry as Map<String, dynamic>;
        final time = map['departure_time'] as String?;
        final tripId = map['trip_id'] as String?;
        final seats = map['available_seats'] as int?;
        if (time != null && tripId != null && seats != null) {
          result[time] = (tripId: tripId, availableSeats: seats);
        }
      }

      return result;
    } on DioException {
      return {};
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
