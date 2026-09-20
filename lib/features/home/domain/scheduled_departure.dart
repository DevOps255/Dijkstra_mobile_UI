import 'package:equatable/equatable.dart';

import 'campus_route.dart';

/// Un départ affichable dans la liste de l'accueil.
///
/// Construit d'abord depuis [CampusSchedule] (déterministe, toujours
/// disponible, fonctionne hors-ligne) puis enrichi si possible par
/// les données réelles d'un `Trip` (places restantes, `tripId` pour
/// l'achat) — voir `TripsRepository`. Tant que l'endpoint réseau
/// n'est pas disponible côté backend, [tripId] et [availableSeats]
/// restent `null` et l'achat est désactivé plutôt que simulé.
class ScheduledDeparture extends Equatable {
  const ScheduledDeparture({
    required this.time,
    required this.direction,
    required this.boardingStop,
    required this.destinationLabel,
    required this.fareFcfa,
    this.tripId,
    this.availableSeats,
    this.isPalaisCongresOnly = false,
  });

  final String time; // "05:30"
  final TripDirection direction;
  final CampusStop boardingStop;
  final String destinationLabel;
  final int fareFcfa;
  final String? tripId;
  final int? availableSeats;
  final bool isPalaisCongresOnly;

  bool get isPurchasable => tripId != null;

  ScheduledDeparture copyWithLiveData({
    required String tripId,
    required int availableSeats,
  }) {
    return ScheduledDeparture(
      time: time,
      direction: direction,
      boardingStop: boardingStop,
      destinationLabel: destinationLabel,
      fareFcfa: fareFcfa,
      tripId: tripId,
      availableSeats: availableSeats,
      isPalaisCongresOnly: isPalaisCongresOnly,
    );
  }

  @override
  List<Object?> get props => [
        time,
        direction,
        boardingStop,
        tripId,
        availableSeats,
      ];
}
