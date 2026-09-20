import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/domain/campus_route.dart';
import '../../../tickets/domain/ticket.dart';
import '../../application/live_tracking_controller.dart';
import '../../data/gps_websocket_client.dart';
import '../../domain/stop_location.dart';
import '../widgets/eta_info_bar.dart';

/// Écran de suivi actif — reproduit la structure de la référence
/// (carte + bandeau de métriques en bas), fond sur OpenStreetMap
/// (décision déjà actée en L37B : gratuit, pas de clé API, cohérent
/// avec le contexte togolais) plutôt que Google Maps.
class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({super.key, required this.ticket});

  final Ticket ticket;

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  final _mapController = MapController();

  /// Heuristique simple faute d'un champ de direction explicite sur
  /// le ticket : Campus Sud en montée => Aller, sinon Retour.
  TripDirection get _direction =>
      widget.ticket.boardingStopId == 'campus_sud' ? TripDirection.aller : TripDirection.retour;

  List<LatLng> get _routePolyline {
    final stops = CampusRoute.stopsFor(_direction);
    return stops.map((s) => StopLocations.forStopId(s.id)).toList();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(liveTrackingControllerProvider.notifier).start(
            lineId: widget.ticket.lineId,
            ticketId: widget.ticket.id,
            destinationStopId: widget.ticket.alightingStopId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveTrackingControllerProvider);
    final boardingPosition = StopLocations.forStopId(widget.ticket.boardingStopId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: boardingPosition,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'tg.univ_kara.dijkstra',
              ),
              PolylineLayer(polylines: [
                Polyline(points: _routePolyline, strokeWidth: 4, color: AppColors.primary.withOpacity(0.7)),
              ]),
              MarkerLayer(markers: [
                Marker(
                  point: boardingPosition,
                  width: 28, height: 28,
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  ),
                ),
                if (state.busPosition != null && state.busPosition!.isFresh)
                  Marker(
                    point: state.busPosition!.position,
                    width: 40, height: 40,
                    child: const _BusMarker(),
                  ),
              ]),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 220,
            child: _ZoomControls(mapController: _mapController),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _BackButton(onTap: () => Navigator.of(context).pop()),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _ConnectionBadge(status: state.status),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: EtaInfoBar(eta: state.eta, lastMessage: state.lastMessage),
          ),
        ],
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({required this.mapController});
  final MapController mapController;

  void _zoom(double delta) {
    final camera = mapController.camera;
    mapController.move(camera.center, (camera.zoom + delta).clamp(3.0, 19.0));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(icon: Icons.add_rounded, onTap: () => _zoom(1)),
          Container(height: 1, color: AppColors.divider),
          _ZoomButton(icon: Icons.remove_rounded, onTap: () => _zoom(-1)),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, size: 20, color: AppColors.textPrimary)),
    );
  }
}

class _BusMarker extends StatelessWidget {
  const _BusMarker();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
      ),
      child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 20),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.arrow_back_rounded, size: 20)),
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.status});
  final GpsConnectionStatus status;

  (String, Color) get _display {
    switch (status) {
      case GpsConnectionStatus.connected:
        return ('En direct', AppColors.success);
      case GpsConnectionStatus.connecting:
      case GpsConnectionStatus.reconnecting:
        return ('Connexion...', AppColors.textTertiary);
      case GpsConnectionStatus.disconnected:
      case GpsConnectionStatus.failed:
        return ('Hors ligne', AppColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = _display;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
