import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/ultrasound/beacon_emitter.dart';
import '../../../core/ultrasound/beacon_receiver.dart';
import '../../../core/ultrasound/frame_codec.dart';
import '../../../core/ultrasound/ultrasound_config.dart';
import '../data/ticket_repository.dart';
import '../domain/ticket_exception.dart';
import '../domain/ticket_totp_code.dart';
import '../domain/validation_outcome.dart';

const _beaconMaxAgeSeconds = 60;
const _listenTimeout = Duration(seconds: 30);

class TicketValidationState {
  const TicketValidationState({
    required this.outcome,
    this.errorMessage,
    this.totpCode,
  });

  factory TicketValidationState.initial() =>
      const TicketValidationState(outcome: ValidationOutcome.idle);

  final ValidationOutcome outcome;
  final String? errorMessage;
  final TicketTotpCode? totpCode;

  TicketValidationState copyWith({
    ValidationOutcome? outcome,
    String? errorMessage,
    TicketTotpCode? totpCode,
    bool clearError = false,
  }) {
    return TicketValidationState(
      outcome: outcome ?? this.outcome,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      totpCode: totpCode ?? this.totpCode,
    );
  }
}

/// Orchestre la validation d'un ticket — flux ultrason PRINCIPAL
/// (le QR code et la saisie manuelle sont des secours distincts,
/// pas des étapes de ce contrôleur ; voir QrFallbackView).
///
/// Séquence :
/// 1. Écoute le micro pour le beacon du chauffeur (trip_id + preuve)
/// 2. Vérifie que trip_id correspond au ticket
/// 3. Récupère le code TOTP + la signature côté serveur
/// 4. Valide le ticket via le réseau (seule opération autoritaire)
/// 5. Émet une confirmation ultrason en meilleur effort (pour la
///    future réception hors-ligne côté chauffeur — n'affecte jamais
///    le résultat déjà acquis à l'étape 4)
class TicketValidationController extends Notifier<TicketValidationState> {
  late final BeaconReceiver _receiver;
  late final BeaconEmitter _emitter;
  late final TicketRepository _repository;

  StreamSubscription? _beaconSubscription;
  Timer? _timeoutTimer;

  @override
  TicketValidationState build() {
    _receiver = getIt<BeaconReceiver>();
    _emitter = getIt<BeaconEmitter>();
    _repository = getIt<TicketRepository>();

    ref.onDispose(() {
      _beaconSubscription?.cancel();
      _timeoutTimer?.cancel();
      _receiver.stopListening();
    });

    return TicketValidationState.initial();
  }

  /// DOIT être appelé depuis un event handler direct (tap du
  /// bouton) — la permission microphone doit être accordée avant
  /// cet appel côté UI.
  Future<void> startUltrasonicValidation({
    required String ticketId,
    required String expectedTripId,
  }) async {
    if (state.outcome == ValidationOutcome.listening) return;

    state = state.copyWith(outcome: ValidationOutcome.listening, clearError: true);

    final stream = await _receiver.startListening();

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_listenTimeout, () {
      if (state.outcome == ValidationOutcome.listening) {
        _beaconSubscription?.cancel();
        _receiver.stopListening();
        state = state.copyWith(
          outcome: ValidationOutcome.timeout,
          errorMessage: 'Aucun signal détecté. Rapprochez-vous du chauffeur ou utilisez le QR code.',
        );
      }
    });

    _beaconSubscription?.cancel();
    _beaconSubscription = stream.listen((frame) async {
      if (frame.frameType != UltrasoundConfig.frameTypeBeacon) return;

      final receivedTripId = bytesToUuidString(frame.subjectIdBytes);
      final nowUnix = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final age = (nowUnix - frame.timestampUnix).abs();

      if (age > _beaconMaxAgeSeconds) {
        _timeoutTimer?.cancel();
        await _stopReceiving();
        state = state.copyWith(
          outcome: ValidationOutcome.beaconExpired,
          errorMessage: 'Signal trop ancien. Restez proche du chauffeur et réessayez.',
        );
        return;
      }

      if (receivedTripId != expectedTripId) {
        // Mauvais bus — on continue d'écouter, l'étudiant est
        // peut-être à portée de plusieurs bus simultanément.
        return;
      }

      _timeoutTimer?.cancel();
      await _stopReceiving();
      await _completeValidation(
        ticketId: ticketId,
        tripId: expectedTripId,
      );
    });
  }

  Future<void> _stopReceiving() async {
    await _beaconSubscription?.cancel();
    await _receiver.stopListening();
  }

  Future<void> _completeValidation({
    required String ticketId,
    required String tripId,
  }) async {
    state = state.copyWith(outcome: ValidationOutcome.fetchingCode, clearError: true);

    TicketTotpCode totpCode;
    try {
      totpCode = await _repository.fetchTotpCode(ticketId);
    } on TicketException catch (error) {
      state = state.copyWith(outcome: ValidationOutcome.failed, errorMessage: error.publicMessage);
      return;
    }

    state = state.copyWith(outcome: ValidationOutcome.submitting, totpCode: totpCode);

    try {
      await _repository.validateTicket(
        ticketId: ticketId,
        tripId: tripId,
        totpCode: totpCode.code6Digits,
        timestampUnix: totpCode.validFromUnix,
      );
    } on TicketException catch (error) {
      state = state.copyWith(outcome: ValidationOutcome.failed, errorMessage: error.publicMessage);
      return;
    }

    state = state.copyWith(outcome: ValidationOutcome.success);

    // Confirmation ultrason en meilleur effort — le résultat de la
    // validation ci-dessus est déjà acquis, cet échec ne doit
    // jamais dégrader l'état affiché à l'étudiant.
    unawaited(_emitConfirmationBestEffort(
      ticketId: ticketId,
      qrSignature: totpCode.qrSignatureBytes,
    ));
  }

  Future<void> _emitConfirmationBestEffort({
    required String ticketId,
    required Uint8List qrSignature,
  }) async {
    try {
      await _emitter.emitOnce(
        frameType: UltrasoundConfig.frameTypeConfirmation,
        subjectIdUuid: ticketId,
        proof: qrSignature,
      );
    } catch (_) {
      // Best-effort — aucune conséquence sur l'état déjà validé.
    }
  }

  void reset() {
    _beaconSubscription?.cancel();
    _timeoutTimer?.cancel();
    _receiver.stopListening();
    state = TicketValidationState.initial();
  }
}

final ticketValidationControllerProvider =
    NotifierProvider<TicketValidationController, TicketValidationState>(
  TicketValidationController.new,
);
