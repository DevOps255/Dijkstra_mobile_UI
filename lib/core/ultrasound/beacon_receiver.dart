import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:injectable/injectable.dart';

import 'frame_codec.dart';
import 'ultrasound_config.dart';
import 'ultrasound_ffi_bridge.dart';

/// Récepteur ultrason générique — capte le micro, décode le flux FSK
/// bit à bit via Goertzel (C++/FFI), reconstruit les trames complètes
/// (CRC déjà vérifié côté C++), et les expose sous forme de
/// [LogicalFrame] décodées. Utilisé par l'étudiant pour recevoir le
/// beacon du chauffeur, et (futur) par le chauffeur pour recevoir
/// les confirmations étudiantes.
@lazySingleton
class BeaconReceiver {
  FlutterSoundRecorder? _recorder;
  Pointer<Void>? _fskCtx;
  Pointer<Void>? _frameDecoder;
  bool _isListening = false;

  StreamController<LogicalFrame>? _framesController;

  bool get isListening => _isListening;

  /// Démarre l'écoute continue. Retourne un stream qui émet chaque
  /// trame valide reçue (CRC déjà vérifié). L'appelant filtre
  /// ensuite par frame_type/subject_id selon son besoin.
  ///
  /// Lève [StateError] si déjà en écoute.
  Future<Stream<LogicalFrame>> startListening() async {
    if (_isListening) {
      throw StateError('BeaconReceiver.startListening : déjà en écoute.');
    }

    _fskCtx = UltrasoundFfiBridge.instance.createContext(
      sampleRate: UltrasoundConfig.sampleRate,
      freqBit0: UltrasoundConfig.freqBit0,
      freqBit1: UltrasoundConfig.freqBit1,
      symbolSamples: UltrasoundConfig.symbolSamples,
    );

    if (_fskCtx == null) {
      throw StateError('BeaconReceiver.startListening : contexte FSK non créé.');
    }

    _frameDecoder = UltrasoundFfiBridge.instance.createFrameDecoder(_fskCtx!);

    if (_frameDecoder == null) {
      UltrasoundFfiBridge.instance.destroyContext(_fskCtx);
      _fskCtx = null;
      throw StateError('BeaconReceiver.startListening : décodeur de trame non créé.');
    }

    _framesController = StreamController<LogicalFrame>.broadcast();

    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();

    _isListening = true;

    final pcmBuffer = <int>[];
    final symbolSize = UltrasoundConfig.symbolSamples;

    final streamController = StreamController<Food>();
    streamController.stream.listen((food) {
      if (food is FoodData && food.data != null) {
        final bytes = food.data!;
        for (var i = 0; i + 1 < bytes.length; i += 2) {
          final int16 = bytes[i] | (bytes[i + 1] << 8);
          final signed = int16 < 0x8000 ? int16 : int16 - 0x10000;
          pcmBuffer.add(signed);
        }

        while (pcmBuffer.length >= symbolSize) {
          final window = pcmBuffer.sublist(0, symbolSize);
          pcmBuffer.removeRange(0, symbolSize);
          _processWindow(window);
        }
      }
    });

    await _recorder!.startRecorder(
      toStream: streamController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: UltrasoundConfig.sampleRate,
    );

    return _framesController!.stream;
  }

  void _processWindow(List<int> pcmSamples) {
    if (!_isListening || _fskCtx == null || _frameDecoder == null) return;

    final floatWindow = Float32List(pcmSamples.length);
    for (var i = 0; i < pcmSamples.length; i++) {
      floatWindow[i] = pcmSamples[i] / 32768.0;
    }

    final bit = UltrasoundFfiBridge.instance.decodeBit(_fskCtx!, floatWindow);
    if (bit == null) return;

    final frameBytes = UltrasoundFfiBridge.instance.feedBit(_frameDecoder!, bit);
    if (frameBytes == null) return;

    final frame = LogicalFrame.fromBytes(frameBytes);
    if (frame != null) {
      _framesController?.add(frame);
    }
  }

  /// Arrête l'écoute et libère toutes les ressources (micro, contexte
  /// natif). Doit toujours être appelé en sortie d'écran — laisser
  /// le micro actif consomme la batterie et alarme l'utilisateur.
  Future<void> stopListening() async {
    _isListening = false;

    await _recorder?.stopRecorder();
    await _recorder?.closeRecorder();
    _recorder = null;

    await _framesController?.close();
    _framesController = null;

    UltrasoundFfiBridge.instance.destroyFrameDecoder(_frameDecoder);
    _frameDecoder = null;

    UltrasoundFfiBridge.instance.destroyContext(_fskCtx);
    _fskCtx = null;
  }
}
