import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../domain/eta_estimate.dart';

/// Traduction directe de l'EtaCalculator TypeScript (Leçon 37B) —
/// même formule de Haversine, mêmes seuils (500m = approche,
/// 10km = trop loin pour un ETA fiable).
abstract final class EtaCalculator {
  static const _earthRadiusMeters = 6371000.0;

  static double distanceMeters(LatLng a, LatLng b) {
    double toRad(double deg) => deg * math.pi / 180;

    final dLat = toRad(b.latitude - a.latitude);
    final dLon = toRad(b.longitude - a.longitude);

    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);

    final h = sinDLat * sinDLat +
        math.cos(toRad(a.latitude)) * math.cos(toRad(b.latitude)) * sinDLon * sinDLon;

    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return _earthRadiusMeters * c;
  }

  static EtaEstimate compute({
    required LatLng busPosition,
    required LatLng stopPosition,
    required double speedKmh,
  }) {
    final distance = distanceMeters(busPosition, stopPosition);
    final isApproaching = distance < 500;

    if (speedKmh <= 0 || distance > 10000) {
      return EtaEstimate(
        distanceMeters: distance.round(),
        estimatedMinutes: null,
        isApproaching: isApproaching,
      );
    }

    final speedMs = speedKmh * 1000 / 3600;
    final etaSeconds = distance / speedMs;

    return EtaEstimate(
      distanceMeters: distance.round(),
      estimatedMinutes: (etaSeconds / 60).ceil(),
      isApproaching: isApproaching,
    );
  }

  const EtaCalculator._();
}
