import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Avatar par défaut quand l'étudiant n'a pas de photo de profil.
///
/// Même principe que les identicons GitHub ou les icônes de dossier
/// Xender : un pattern visuel déterministe dérivé d'une chaîne
/// (généralement l'ID étudiant), symétrique, coloré, jamais deux
/// utilisateurs différents avec le même pattern par hasard grâce au
/// hash — et surtout, zéro dépendance réseau, zéro asset à charger.
///
/// Le réglage de la photo réelle est prévu plus tard (paramètres,
/// comme mentionné) — ce widget est le fallback permanent tant
/// qu'aucune photo n'est définie.
class IdenticonAvatar extends StatelessWidget {
  const IdenticonAvatar({
    super.key,
    required this.seed,
    this.size = 40,
  });

  final String seed;
  final double size;

  static const List<Color> _palette = [
    AppColors.primary,
    Color(0xFF7C5CFF), // violet lavande — cohérent avec la teinte texte
    Color(0xFF16A34A),
    Color(0xFFD97706),
    Color(0xFF2FA8FF),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _IdenticonPainter(seed: seed, palette: _palette),
        ),
      ),
    );
  }
}

class _IdenticonPainter extends CustomPainter {
  _IdenticonPainter({required this.seed, required this.palette});

  final String seed;
  final List<Color> palette;

  static const int _grid = 5; // grille 5x5, colonnes 0-2 reflétées sur 3-4

  @override
  void paint(Canvas canvas, Size size) {
    final int hash = seed.isEmpty ? 0 : seed.codeUnits.fold(0, (a, b) => a * 31 + b);
    final random = Random(hash);

    final Color foreground = palette[hash.abs() % palette.length];
    final Paint bgPaint = Paint()..color = AppColors.surfaceElevated;
    final Paint fgPaint = Paint()..color = foreground;

    canvas.drawRect(Offset.zero & size, bgPaint);

    final double cell = size.width / _grid;

    // Colonnes 0,1,2 générées aléatoirement (déterministe via seed),
    // colonnes 3,4 = miroir de 1,0 — garantit la symétrie horizontale
    // caractéristique du style identicon.
    final List<List<bool>> matrix = List.generate(
      _grid,
      (_) => List.generate(3, (_) => random.nextDouble() > 0.55),
    );

    for (int row = 0; row < _grid; row++) {
      for (int col = 0; col < _grid; col++) {
        final int sourceCol = col < 3 ? col : (_grid - 1 - col);
        final bool filled = matrix[row][sourceCol];
        if (filled) {
          canvas.drawRect(
            Rect.fromLTWH(col * cell, row * cell, cell, cell),
            fgPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IdenticonPainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}
