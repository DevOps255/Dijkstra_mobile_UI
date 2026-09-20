import 'package:audioplayers/audioplayers.dart';
import 'package:injectable/injectable.dart';

/// Sons d'interaction courts (< 300ms), jamais de musique ni de son
/// long — l'objectif est un feedback tactile-sonore discret, pas une
/// ambiance.
///
/// Fichiers audio NON fournis dans cette livraison (même logique que
/// la vidéo d'onboarding) — à déposer dans `assets/audio/`. Format
/// recommandé : `.mp3` ou `.m4a`, < 50 Ko, < 300ms.
@lazySingleton
class SoundService {
  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  /// Grincement mécanique bref — joué au changement de date
  /// sélectionnée dans le défileur de jours.
  Future<void> playDateScrollTick() => _play('mechanical_tick.mp3');

  void setEnabled(bool value) => _enabled = value;

  Future<void> _play(String assetFileName) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/$assetFileName'));
    } catch (_) {
      // Un son manquant ou un échec de lecture ne doit jamais
      // perturber l'interaction principale — dégradation silencieuse.
    }
  }

  Future<void> dispose() => _player.dispose();
}
