import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../map/domain/stop_location.dart';

/// Prévisualisation compacte de la position des bus en direct.
///
/// Vraie carte OpenStreetMap (flutter_map), pas un dessin décoratif
/// — même moteur de rendu que l'onglet Carte dédié. Interactions
/// désactivées ici volontairement (`InteractiveFlag.none`) : cette
/// vignette sert d'appel vers l'onglet Carte complet, pas d'une
/// deuxième surface de carte manipulable dans le flux de défilement
/// de l'accueil, ce qui créerait des conflits de gestes.
///
/// Attribution OpenStreetMap incluse — obligatoire même sur une
/// vignette de petite taille (politique d'usage des tuiles OSM).
class LiveMapPreviewCard extends StatelessWidget {
  const LiveMapPreviewCard({super.key, required this.onOpenMap});

  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onOpenMap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 5)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                // La vignette n'intercepte aucun geste — le tap
                // entier de la carte (via PressableScale ci-dessus)
                // ouvre l'onglet Carte, jamais un pan/zoom local ici.
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: StopLocations.kayaReferencePoint,
                    initialZoom: 13.5,
                    interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'tg.univ_kara.dijkstra',
                    ),
                    RichAttributionWidget(
                      alignment: AttributionAlignment.bottomLeft,
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Voile sombre léger pour garantir la lisibilité du texte
            // par-dessus la carte, quelle que soit la zone géographique
            // affichée sous la vignette.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 14,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bus en direct',
                    style: AppTypography.label.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  'Voir la carte en direct',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
