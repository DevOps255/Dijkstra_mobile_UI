import 'package:equatable/equatable.dart';

/// Sens de circulation du bus — remplace fonctionnellement les
/// onglets "One way / Round trip" de la référence, en conservant
/// exactement la même géométrie de composant (deux segments).
enum TripDirection { aller, retour }

/// Un arrêt réel de la ligne Campus Sud ↔ Campus Nord.
///
/// [minutesFromOrigin] est une estimation cumulée depuis le premier
/// arrêt de CHAQUE sens (Campus Sud pour l'Aller, Campus Nord pour le
/// Retour) — utilisée uniquement pour l'affichage d'un ordre de
/// grandeur du temps de trajet restant, jamais comme donnée
/// contractuelle (le vrai suivi vient du GPS temps réel, L37A/B).
class CampusStop extends Equatable {
  const CampusStop({
    required this.id,
    required this.name,
    required this.minutesFromOrigin,
    this.isBranchStop = false,
    this.branchNote,
  });

  final String id;
  final String name;
  final int minutesFromOrigin;

  /// `true` pour Palais des Congrès — seul arrêt qui n'est pas sur la
  /// ligne droite habituelle (détour depuis Immeuble Tagba) et qui
  /// n'est desservi qu'au tout premier départ de la journée.
  final bool isBranchStop;
  final String? branchNote;

  @override
  List<Object?> get props => [id, name, minutesFromOrigin];
}

/// Encodage direct de la description fournie — deux séquences
/// d'arrêts distinctes selon le sens, exactement comme décrit (les
/// arrêts et leur ordre diffèrent réellement entre Aller et Retour,
/// ce n'est pas une simple inversion de liste).
abstract final class CampusRoute {
  static const List<CampusStop> allerStops = [
    CampusStop(id: 'campus_sud', name: 'Campus Sud', minutesFromOrigin: 0),
    CampusStop(id: 'shell_1', name: 'Shell 1', minutesFromOrigin: 10),
    CampusStop(id: 'tagba', name: 'Immeuble Tagba', minutesFromOrigin: 15),
    CampusStop(
      id: 'palais_congres',
      name: 'Palais des Congrès',
      minutesFromOrigin: 20,
      isBranchStop: true,
      branchNote: 'Desservi uniquement au départ de 5h30',
    ),
    CampusStop(id: 'shell_2', name: 'Shell 2', minutesFromOrigin: 22),
    CampusStop(id: 'bohou', name: 'Bohou', minutesFromOrigin: 27),
    CampusStop(id: 'tchitchao', name: 'Tchitchao', minutesFromOrigin: 33),
    CampusStop(id: 'campus_nord', name: 'Campus Nord', minutesFromOrigin: 45),
  ];

  static const List<CampusStop> retourStops = [
    CampusStop(id: 'campus_nord', name: 'Campus Nord', minutesFromOrigin: 0),
    CampusStop(id: 'tchitchao', name: 'Tchitchao', minutesFromOrigin: 12),
    CampusStop(id: 'eglise', name: 'Église', minutesFromOrigin: 16),
    CampusStop(id: 'bohou', name: 'Bohou', minutesFromOrigin: 20),
    CampusStop(id: 'shell_2', name: 'Shell 2', minutesFromOrigin: 25),
    CampusStop(
      id: 'palais_congres',
      name: 'Palais des Congrès',
      minutesFromOrigin: 27,
    ),
    CampusStop(id: 'tagba', name: 'Immeuble Tagba', minutesFromOrigin: 30),
    CampusStop(id: 'shell_1', name: 'Shell 1', minutesFromOrigin: 35),
    CampusStop(id: 'campus_sud', name: 'Campus Sud', minutesFromOrigin: 45),
  ];

  /// Service additionnel du soir (~18h), après le retour principal —
  /// ne fait pas l'arrêt à Campus Sud comme terminus mais continue
  /// vers Soumdina, en reprenant les étudiants du campus sud à partir
  /// de Tchitchao.
  static const List<CampusStop> soumdinaEveningStops = [
    CampusStop(id: 'tchitchao', name: 'Tchitchao', minutesFromOrigin: 0),
    CampusStop(id: 'eglise', name: 'Église', minutesFromOrigin: 4),
    CampusStop(id: 'bohou', name: 'Bohou', minutesFromOrigin: 8),
    CampusStop(id: 'shell_2', name: 'Shell 2', minutesFromOrigin: 13),
    CampusStop(id: 'tagba', name: 'Immeuble Tagba', minutesFromOrigin: 18),
    CampusStop(id: 'shell_1', name: 'Shell 1', minutesFromOrigin: 23),
    CampusStop(id: 'campus_sud', name: 'Campus Sud', minutesFromOrigin: 33),
    CampusStop(id: 'soumdina', name: 'Soumdina', minutesFromOrigin: 40),
  ];

  static List<CampusStop> stopsFor(TripDirection direction) {
    return direction == TripDirection.aller ? allerStops : retourStops;
  }

  static String destinationFor(TripDirection direction) {
    return direction == TripDirection.aller ? 'Campus Nord' : 'Campus Sud';
  }

  const CampusRoute._();
}

/// Créneaux horaires réels par sens — l'Aller ne dépasse jamais 7h30
/// (règle explicite), le Retour couvre l'après-midi.
///
/// Ces listes seront à terme remplacées par un appel réseau vers
/// `GET /trips?direction=...&date=...` (schéma Trip, L33) — elles
/// sont codées en dur ici en attendant que cet endpoint existe côté
/// backend, exactement dans l'esprit de `check-email` : une donnée
/// nécessaire au flux, absente du contrat fourni, isolée et signalée.
abstract final class CampusSchedule {
  static const List<String> allerDepartures = [
    '05:30',
    '06:00',
    '06:30',
    '07:00',
    '07:30',
  ];

  static const List<String> retourDepartures = [
    '13:00',
    '14:00',
    '15:00',
    '16:00',
  ];

  static const String eveningDeparture = '18:00';

  static List<String> departuresFor(TripDirection direction) {
    return direction == TripDirection.aller
        ? allerDepartures
        : retourDepartures;
  }

  const CampusSchedule._();
}
