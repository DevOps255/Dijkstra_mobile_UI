import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

typedef _CreateC = Pointer<Void> Function(
    Int32 sampleRate, Double freqBit0, Double freqBit1, Int32 symbolSamples);
typedef _CreateDart = Pointer<Void> Function(
    int sampleRate, double freqBit0, double freqBit1, int symbolSamples);

typedef _DestroyC = Void Function(Pointer<Void> ctx);
typedef _DestroyDart = void Function(Pointer<Void> ctx);

typedef _RequiredSamplesC = Int32 Function(Pointer<Void> ctx);
typedef _RequiredSamplesDart = int Function(Pointer<Void> ctx);

typedef _EncodeFrameC = Int32 Function(
    Pointer<Void> ctx, Pointer<Uint8> frameBytes, Pointer<Float> output, Int32 outputLen);
typedef _EncodeFrameDart = int Function(
    Pointer<Void> ctx, Pointer<Uint8> frameBytes, Pointer<Float> output, int outputLen);

typedef _DecodeBitC = Int32 Function(
    Pointer<Void> ctx, Pointer<Float> audioInput, Int32 inputLen, Pointer<Uint8> outputBit);
typedef _DecodeBitDart = int Function(
    Pointer<Void> ctx, Pointer<Float> audioInput, int inputLen, Pointer<Uint8> outputBit);

typedef _FrameDecoderCreateC = Pointer<Void> Function(Pointer<Void> fskCtx);
typedef _FrameDecoderCreateDart = Pointer<Void> Function(Pointer<Void> fskCtx);

typedef _FrameDecoderDestroyC = Void Function(Pointer<Void> decoder);
typedef _FrameDecoderDestroyDart = void Function(Pointer<Void> decoder);

typedef _FrameDecoderResetC = Void Function(Pointer<Void> decoder);
typedef _FrameDecoderResetDart = void Function(Pointer<Void> decoder);

typedef _FrameDecoderFeedBitC = Int32 Function(
    Pointer<Void> decoder, Uint8 bit, Pointer<Uint8> outputFrame, Int32 outputLen);
typedef _FrameDecoderFeedBitDart = int Function(
    Pointer<Void> decoder, int bit, Pointer<Uint8> outputFrame, int outputLen);

/// Pont dart:ffi vers `native/ultrasound_fsk/ultrasound_fsk.cpp`.
///
/// Un seul binaire natif, utilisé dans les deux sens : le chauffeur
/// appelle les fonctions d'encodage pour émettre son beacon, et
/// l'étudiant appelle les fonctions de décodage pour le recevoir —
/// puis le rôle s'inverse pour la confirmation retour. Rien dans
/// ce pont ne dépend du rôle ; c'est l'app Dart qui décide quelles
/// fonctions appeler et quand.
class UltrasoundFfiBridge {
  static UltrasoundFfiBridge? _instance;

  late final DynamicLibrary _lib;
  late final _CreateDart _create;
  late final _DestroyDart _destroy;
  late final _RequiredSamplesDart _requiredSamples;
  late final _EncodeFrameDart _encodeFrame;
  late final _DecodeBitDart _decodeBit;
  late final _FrameDecoderCreateDart _frameDecoderCreate;
  late final _FrameDecoderDestroyDart _frameDecoderDestroy;
  late final _FrameDecoderResetDart _frameDecoderReset;
  late final _FrameDecoderFeedBitDart _frameDecoderFeedBit;

  UltrasoundFfiBridge._internal() {
    _lib = _loadLibrary();
    _create = _lib.lookupFunction<_CreateC, _CreateDart>('ultrasound_fsk_create');
    _destroy = _lib.lookupFunction<_DestroyC, _DestroyDart>('ultrasound_fsk_destroy');
    _requiredSamples = _lib.lookupFunction<_RequiredSamplesC, _RequiredSamplesDart>(
        'ultrasound_fsk_required_samples_for_frame');
    _encodeFrame = _lib.lookupFunction<_EncodeFrameC, _EncodeFrameDart>(
        'ultrasound_fsk_encode_frame');
    _decodeBit = _lib.lookupFunction<_DecodeBitC, _DecodeBitDart>(
        'ultrasound_fsk_decode_bit');
    _frameDecoderCreate = _lib.lookupFunction<_FrameDecoderCreateC, _FrameDecoderCreateDart>(
        'ultrasound_frame_decoder_create');
    _frameDecoderDestroy = _lib.lookupFunction<_FrameDecoderDestroyC, _FrameDecoderDestroyDart>(
        'ultrasound_frame_decoder_destroy');
    _frameDecoderReset = _lib.lookupFunction<_FrameDecoderResetC, _FrameDecoderResetDart>(
        'ultrasound_frame_decoder_reset');
    _frameDecoderFeedBit = _lib.lookupFunction<_FrameDecoderFeedBitC, _FrameDecoderFeedBitDart>(
        'ultrasound_frame_decoder_feed_bit');
  }

  static UltrasoundFfiBridge get instance {
    _instance ??= UltrasoundFfiBridge._internal();
    return _instance!;
  }

  static DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libultrasound_fsk.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    }
    throw UnsupportedError(
      'UltrasoundFfiBridge : plateforme non supportée : ${Platform.operatingSystem}.',
    );
  }

  Pointer<Void>? createContext({
    required int sampleRate,
    required double freqBit0,
    required double freqBit1,
    required int symbolSamples,
  }) {
    final ptr = _create(sampleRate, freqBit0, freqBit1, symbolSamples);
    return ptr.address == 0 ? null : ptr;
  }

  void destroyContext(Pointer<Void>? ctx) {
    if (ctx == null || ctx.address == 0) return;
    _destroy(ctx);
  }

  int requiredSamplesForFrame(Pointer<Void> ctx) => _requiredSamples(ctx);

  /// Encode une trame logique de 33 bytes en signal audio. Retourne
  /// null si l'encodage échoue (contexte invalide, taille incorrecte).
  Float32List? encodeFrame(Pointer<Void> ctx, Uint8List frameBytes) {
    final required = _requiredSamples(ctx);
    if (required <= 0) return null;

    final nativeFrame = calloc<Uint8>(frameBytes.length);
    final nativeOutput = calloc<Float>(required);

    try {
      for (var i = 0; i < frameBytes.length; i++) {
        nativeFrame[i] = frameBytes[i];
      }

      final written = _encodeFrame(ctx, nativeFrame, nativeOutput, required);
      if (written <= 0) return null;

      final result = Float32List(written);
      for (var i = 0; i < written; i++) {
        result[i] = nativeOutput[i];
      }
      return result;
    } finally {
      calloc.free(nativeFrame);
      calloc.free(nativeOutput);
    }
  }

  /// Décode un bit depuis une fenêtre audio de symbol_samples
  /// échantillons. Retourne null si le signal est trop faible pour
  /// une décision fiable.
  int? decodeBit(Pointer<Void> ctx, Float32List audioWindow) {
    final nativeInput = calloc<Float>(audioWindow.length);
    final nativeOutputBit = calloc<Uint8>(1);

    try {
      for (var i = 0; i < audioWindow.length; i++) {
        nativeInput[i] = audioWindow[i];
      }

      final result = _decodeBit(ctx, nativeInput, audioWindow.length, nativeOutputBit);
      if (result != 1) return null;
      return nativeOutputBit[0];
    } finally {
      calloc.free(nativeInput);
      calloc.free(nativeOutputBit);
    }
  }

  Pointer<Void>? createFrameDecoder(Pointer<Void> fskCtx) {
    final ptr = _frameDecoderCreate(fskCtx);
    return ptr.address == 0 ? null : ptr;
  }

  void destroyFrameDecoder(Pointer<Void>? decoder) {
    if (decoder == null || decoder.address == 0) return;
    _frameDecoderDestroy(decoder);
  }

  void resetFrameDecoder(Pointer<Void> decoder) => _frameDecoderReset(decoder);

  /// Alimente le décodeur de trame avec un bit. Retourne les 33
  /// bytes de la trame logique si elle est complète ET que son CRC
  /// est valide, null sinon (trame incomplète ou bruit rejeté par
  /// le CRC interne au C++).
  Uint8List? feedBit(Pointer<Void> decoder, int bit) {
    final outputPtr = calloc<Uint8>(64); // marge, taille reelle = 33

    try {
      final result = _frameDecoderFeedBit(decoder, bit, outputPtr, 64);
      if (result <= 0) return null;

      final frame = Uint8List(result);
      for (var i = 0; i < result; i++) {
        frame[i] = outputPtr[i];
      }
      return frame;
    } finally {
      calloc.free(outputPtr);
    }
  }
}
