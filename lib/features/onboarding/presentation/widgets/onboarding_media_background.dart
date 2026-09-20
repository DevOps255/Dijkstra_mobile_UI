import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

/// Fond plein écran de l'onboarding.
///
/// Stratégie de résilience à trois niveaux, essentielle sur les
/// téléphones d'entrée de gamme des étudiants :
/// 1. Tente de charger et jouer la vidéo du bus (asset local, donc
///    aucune dépendance réseau).
/// 2. Si l'initialisation vidéo échoue (décodeur H.264 hardware
///    absent, asset corrompu) → bascule automatiquement sur
///    l'animation Lottie, nettement moins coûteuse en CPU/mémoire.
/// 3. Si même Lottie échoue → fond statique uni, jamais d'écran
///    blanc ni d'exception visible à l'étudiant.
class OnboardingMediaBackground extends StatefulWidget {
  const OnboardingMediaBackground({super.key});

  @override
  State<OnboardingMediaBackground> createState() =>
      _OnboardingMediaBackgroundState();
}

class _OnboardingMediaBackgroundState
    extends State<OnboardingMediaBackground> {
  VideoPlayerController? _videoController;
  bool _videoFailed = false;
  bool _lottieFailed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller =
        VideoPlayerController.asset(AppAssets.onboardingBusVideo);

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0); // silencieux — règle de sécurité UX
      await controller.play();
      setState(() => _videoController = controller);
    } catch (_) {
      // Aucune trace d'erreur brute affichée à l'utilisateur —
      // bascule silencieuse vers le fallback Lottie.
      await controller.dispose();
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoController;

    if (controller != null && controller.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      );
    }

    if (_videoFailed && !_lottieFailed) {
      return lottie.Lottie.asset(
        AppAssets.onboardingBusLottie,
        fit: BoxFit.cover,
        repeat: true,
        errorBuilder: (context, error, stackTrace) {
          // Déclenche le dernier niveau de repli au prochain build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _lottieFailed = true);
          });
          return ColoredBox(color: AppColors.background);
        },
      );
    }

    return ColoredBox(color: AppColors.background);
  }
}
