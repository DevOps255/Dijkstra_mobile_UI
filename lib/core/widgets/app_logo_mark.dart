import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Icône de marque — un petit graphe à 4 nœuds avec un chemin
/// surligné, en écho direct au nom "Dijkstra" (algorithme du plus
/// court chemin). Dessiné en `CustomPainter`, pas une image — net à
/// n'importe quelle taille, zéro asset à charger.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: CustomPaint(painter: _GraphMarkPainter()),
    );
  }
}

class _GraphMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final nodes = [
      Offset(size.width * 0.22, size.height * 0.75),
      Offset(size.width * 0.5, size.height * 0.28),
      Offset(size.width * 0.78, size.height * 0.75),
      Offset(size.width * 0.5, size.height * 0.62),
    ];

    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    final pathPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    // Arêtes secondaires du graphe (non empruntées par le "plus
    // court chemin" mis en avant).
    canvas.drawLine(nodes[0], nodes[3], edgePaint);
    canvas.drawLine(nodes[3], nodes[2], edgePaint);

    // Chemin surligné — la métaphore centrale de la marque.
    canvas.drawLine(nodes[0], nodes[1], pathPaint);
    canvas.drawLine(nodes[1], nodes[2], pathPaint);

    final nodeRadius = size.width * 0.075;
    for (final node in nodes) {
      canvas.drawCircle(node, nodeRadius, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphMarkPainter oldDelegate) => false;
}

/// Nom de l'app + logo, ensemble — le bloc à placer en haut à gauche
/// de chaque écran principal (accueil, et plus tard chauffeur/profil).
/// Taille et graisse volontairement imposantes, tracking serré —
/// même registre visuel que WhatsApp/Netflix/YouTube, pas un simple
/// libellé de coin d'écran.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.logoSize = 32, this.textColor});

  final double logoSize;

  /// Force une couleur de texte — nécessaire sur l'onboarding, où le
  /// fond est une vidéo toujours sombre indépendamment du thème
  /// système (voir `AppColors.onVideoPrimary`).
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogoMark(size: logoSize),
        const SizedBox(width: 10),
        Text(
          'Dijkstra',
          style: textColor != null
              ? AppTypography.wordmark.copyWith(color: textColor)
              : AppTypography.wordmark,
        ),
      ],
    );
  }
}
