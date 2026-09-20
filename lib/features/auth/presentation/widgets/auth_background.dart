import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Fond de tout le flux d'authentification — light mode.
///
/// Un blanc plat est correct mais froid. Un halo radial très discret
/// (bleu primaire, ~6% d'opacité) ancré en haut à gauche donne de la
/// profondeur sans jamais compromettre le contraste du texte sombre.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.background),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -140,
            left: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x0F2F6BFF),
                    Color(0x00FAFAFF),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            right: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x0A2F6BFF),
                    Color(0x00FAFAFF),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
