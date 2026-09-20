import 'package:latlong2/latlong.dart';

/// Coordonnées GPS des arrêts, indexées par le même [CampusStop.id]
/// que `features/home/domain/campus_route.dart`.
///
/// ⚠️ DONNÉES PROVISOIRES — seule la position de l'Université de
/// Kara (source : Wikipédia, "University of Kara", 9°31′50″N
/// 1°12′30″E) est réelle. Les autres arrêts sont positionnés le
/// long d'une ligne approximative autour de ce point, uniquement
/// pour que la carte s'affiche pendant le développement — ce ne
/// sont PAS des positions réelles et ne doivent jamais être
/// présentées comme telles à un étudiant. Remplace ces valeurs par
/// les vraies coordonnées (relevées au GPS sur le terrain, ou
/// depuis OpenStreetMap) avant toute mise en production.
abstract final class StopLocations {
  static const LatLng kayaReferencePoint = LatLng(9.53056, 1.20833); // Université de Kara — réel

  static const Map<String, LatLng> coordinates = {
    'campus_sud': LatLng(9.5240, 1.2050), // PLACEHOLDER
    'shell_1': LatLng(9.5270, 1.2060), // PLACEHOLDER
    'tagba': LatLng(9.5290, 1.2065), // PLACEHOLDER
    'palais_congres': LatLng(9.5300, 1.2070), // PLACEHOLDER
    'shell_2': LatLng(9.5310, 1.2075), // PLACEHOLDER
    'bohou': LatLng(9.5330, 1.2078), // PLACEHOLDER
    'eglise': LatLng(9.5340, 1.2080), // PLACEHOLDER
    'tchitchao': LatLng(9.5360, 1.2082), // PLACEHOLDER
    'campus_nord': LatLng(9.5390, 1.2085), // PLACEHOLDER — Université de Kara réelle
    'soumdina': LatLng(9.5420, 1.2090), // PLACEHOLDER
  };

  /// Retourne la position connue d'un arrêt, ou [kayaReferencePoint]
  /// si l'id est inconnu — jamais null, pour que l'affichage
  /// carte reste toujours robuste même avec des données incomplètes.
  static LatLng forStopId(String id) => coordinates[id] ?? kayaReferencePoint;

  const StopLocations._();
}
