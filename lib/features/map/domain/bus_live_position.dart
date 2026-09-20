import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class BusLivePosition extends Equatable {
  const BusLivePosition({
    required this.tripId,
    required this.position,
    required this.speedKmh,
    required this.timestampUnix,
  });

  factory BusLivePosition.fromEventData(Map<String, dynamic> data, int timestampUnix) {
    return BusLivePosition(
      tripId: data['trip_id'] as String? ?? '',
      position: LatLng(
        (data['lat'] as num?)?.toDouble() ?? 0.0,
        (data['lon'] as num?)?.toDouble() ?? 0.0,
      ),
      speedKmh: (data['speed_kmh'] as num?)?.toDouble() ?? 0.0,
      timestampUnix: timestampUnix,
    );
  }

  final String tripId;
  final LatLng position;
  final double speedKmh;
  final int timestampUnix;

  /// Fraîcheur — au-delà de 60s (TTL Redis côté serveur, L37A),
  /// cette position ne doit plus être affichée comme actuelle.
  bool get isFresh {
    final nowUnix = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return (nowUnix - timestampUnix).abs() <= 60;
  }

  @override
  List<Object?> get props => [tripId, position, timestampUnix];
}
