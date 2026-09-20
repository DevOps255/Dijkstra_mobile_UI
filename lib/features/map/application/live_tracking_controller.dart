import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/di/injection.dart';
import '../data/gps_websocket_client.dart';
import '../domain/bus_live_position.dart';
import '../domain/eta_estimate.dart';
import '../domain/stop_location.dart';
import 'eta_calculator.dart';

class LiveTrackingState {
  const LiveTrackingState({
    required this.status,
    this.busPosition,
    this.eta,
    this.lastMessage,
  });

  factory LiveTrackingState.initial() =>
      const LiveTrackingState(status: GpsConnectionStatus.connecting);

  final GpsConnectionStatus status;
  final BusLivePosition? busPosition;
  final EtaEstimate? eta;
  final String? lastMessage;

  LiveTrackingState copyWith({
    GpsConnectionStatus? status,
    BusLivePosition? busPosition,
    EtaEstimate? eta,
    String? lastMessage,
  }) {
    return LiveTrackingState(
      status: status ?? this.status,
      busPosition: busPosition ?? this.busPosition,
      eta: eta ?? this.eta,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

class LiveTrackingController extends Notifier<LiveTrackingState> {
  late final GpsWebSocketClient _client;
  StreamSubscription? _eventSub;
  StreamSubscription? _statusSub;

  LatLng? _destinationStopPosition;

  @override
  LiveTrackingState build() {
    _client = getIt<GpsWebSocketClient>();
    ref.onDispose(() {
      _eventSub?.cancel();
      _statusSub?.cancel();
      _client.dispose();
    });
    return LiveTrackingState.initial();
  }

  void start({
    required String lineId,
    required String ticketId,
    required String destinationStopId,
  }) {
    _destinationStopPosition = StopLocations.forStopId(destinationStopId);

    _statusSub = _client.status.listen((status) {
      state = state.copyWith(status: status);
    });

    _eventSub = _client.events.listen((event) {
      switch (event.type) {
        case 'driver_position':
          final nowUnix = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
          final position = BusLivePosition.fromEventData(event.data, nowUnix);
          final eta = _destinationStopPosition != null
              ? EtaCalculator.compute(
                  busPosition: position.position,
                  stopPosition: _destinationStopPosition!,
                  speedKmh: position.speedKmh,
                )
              : null;
          state = state.copyWith(busPosition: position, eta: eta);
        case 'trip_started':
        case 'bus_approaching':
          final message = event.data['message'] as String?;
          if (message != null) state = state.copyWith(lastMessage: message);
      }
    });

    _client.connect(lineId: lineId, ticketId: ticketId);
  }
}

final liveTrackingControllerProvider =
    NotifierProvider<LiveTrackingController, LiveTrackingState>(LiveTrackingController.new);
