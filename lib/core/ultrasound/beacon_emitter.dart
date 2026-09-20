import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:injectable/injectable.dart';

import 'frame_codec.dart';
import 'ultrasound_config.dart';
import 'ultrasound_ffi_bridge.dart';

/// Émetteur ultrason générique — encode une [LogicalFrame] en signal
/// FSK et le joue via le haut-parleur. Utilisé par le chauffeur pour
/// le beacon de trajet, et par l'étudiant pour la confirmation de
/// ticket : la même classe sert les deux rôles, seul le contenu de
/// la trame diffère.
@lazySingleton
class BeaconEmitter {
  FlutterSoundPlayer? _player;
  Pointer<Void>? _fskCtx;
  bool _isPlaying = false;
  int _sequenceCounter = 0;

  bool get isPlaying => _isPlaying;

  /// Émet UNE trame, une seule fois, et retourne quand la lecture
  /// est terminée. Pour un beacon répété (chauffeur), l'appelant
  /// boucle sur cette méthode à l'intervalle souhaité.
  ///
  /// [frameType] : UltrasoundConfig.frameTypeBeacon ou
  /// UltrasoundConfig.frameTypeConfirmation.
  /// [subjectIdUuid] : trip_id (beacon) ou ticket_id (confirmation).
  /// [proof] : exactement 8 bytes — HMAC device chauffeur, ou
  /// signature émise par le serveur. Jamais calculée localement
  /// pour une confirmation étudiant.
  ///
  /// Lève [StateError] si une émission est déjà en cours.
  Future<void> emitOnce({
    required int frameType,
    required String subjectIdUuid,
    required Uint8List proof,
  }) async {
    if (_isPlaying) {
      throw StateError('BeaconEmitter.emitOnce : émission déjà en cours.');
    }

    final frame = LogicalFrame(
      frameType: frameType,
      sequence: _nextSequence(),
      subjectIdBytes: uuidStringToBytes(subjectIdUuid),
      timestampUnix: DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
      proof: proof,
    );

    _fskCtx = UltrasoundFfiBridge.instance.createContext(
      sampleRate: UltrasoundConfig.sampleRate,
      freqBit0: UltrasoundConfig.freqBit0,
      freqBit1: UltrasoundConfig.freqBit1,
      symbolSamples: UltrasoundConfig.symbolSamples,
    );

    if (_fskCtx == null) {
      throw StateError('BeaconEmitter.emitOnce : contexte FSK non créé.');
    }

    final audioSamples = UltrasoundFfiBridge.instance.encodeFrame(
      _fskCtx!,
      frame.toBytes(),
    );

    if (audioSamples == null || audioSamples.isEmpty) {
      UltrasoundFfiBridge.instance.destroyContext(_fskCtx);
      _fskCtx = null;
      throw StateError('BeaconEmitter.emitOnce : encodage échoué.');
    }

    _isPlaying = true;

    try {
      _player = FlutterSoundPlayer();
      await _player!.openPlayer();

      await _player!.startPlayerFromStream(
        codec: Codec.pcmFloat32,
        numChannels: 1,
        sampleRate: UltrasoundConfig.sampleRate,
      );

      await _player!.feedUint8FromStream(audioSamples.buffer.asUint8List());

      // Attend la durée réelle du signal avant de considérer
      // l'émission terminée — feedFromStream retourne dès que les
      // données sont mises en file, pas quand elles sont jouées.
      await Future.delayed(UltrasoundConfig.frameDuration);

      await _player!.stopPlayer();
      await _player!.closePlayer();
      _player = null;
    } finally {
      UltrasoundFfiBridge.instance.destroyContext(_fskCtx);
      _fskCtx = null;
      _isPlaying = false;
    }
  }

  /// Arrête immédiatement une émission en cours, si applicable.
  Future<void> stop() async {
    if (!_isPlaying) return;
    await _player?.stopPlayer();
    await _player?.closePlayer();
    _player = null;
    UltrasoundFfiBridge.instance.destroyContext(_fskCtx);
    _fskCtx = null;
    _isPlaying = false;
  }

  int _nextSequence() {
    _sequenceCounter = (_sequenceCounter + 1) & 0xFFFF;
    return _sequenceCounter;
  }
}
