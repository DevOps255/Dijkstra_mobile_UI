import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/mobile_money/intercepted_sms.dart';
import '../../../core/mobile_money/mobile_money_config.dart';
import '../../../core/mobile_money/mobile_money_permission_service.dart';
import '../../../core/mobile_money/sim_info.dart';
import '../../../core/mobile_money/sim_selector_service.dart';
import '../../../core/mobile_money/sms_interceptor_service.dart';
import '../../../core/mobile_money/ussd_dialer_service.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet_exception.dart';

enum RechargeStep {
  selectOperator, enterAmount, requestingPermission, permissionDenied,
  permissionPermanentlyDenied, selectSim, dialing, waitingForSms,
  submitting, success, failed,
}

class RechargeFlowState {
  const RechargeFlowState({
    required this.step, this.operator, this.amountFcfa, this.errorMessage,
    this.amountCreditedFcfa, this.newBalanceFcfa, this.availableSims = const [],
  });

  factory RechargeFlowState.initial() =>
      const RechargeFlowState(step: RechargeStep.selectOperator);

  final RechargeStep step;
  final MobileOperator? operator;
  final int? amountFcfa;
  final String? errorMessage;
  final int? amountCreditedFcfa;
  final int? newBalanceFcfa;
  final List<SimInfo> availableSims;

  RechargeFlowState copyWith({
    RechargeStep? step, MobileOperator? operator, int? amountFcfa,
    String? errorMessage, int? amountCreditedFcfa, int? newBalanceFcfa,
    List<SimInfo>? availableSims, bool clearError = false,
  }) {
    return RechargeFlowState(
      step: step ?? this.step,
      operator: operator ?? this.operator,
      amountFcfa: amountFcfa ?? this.amountFcfa,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      amountCreditedFcfa: amountCreditedFcfa ?? this.amountCreditedFcfa,
      newBalanceFcfa: newBalanceFcfa ?? this.newBalanceFcfa,
      availableSims: availableSims ?? this.availableSims,
    );
  }
}

/// RÈGLE ABSOLUE : aucune méthode ici n'accepte de texte de SMS saisi
/// ou collé par l'utilisateur. La seule source de `sms_text` envoyée
/// au backend est un SMS effectivement intercepté par l'OS.
class RechargeFlowController extends Notifier<RechargeFlowState> {
  late final MobileMoneyPermissionService _permissionService;
  late final SimSelectorService _simSelectorService;
  late final UssdDialerService _dialerService;
  late final SmsInterceptorService _smsService;
  late final WalletRepository _walletRepository;

  StreamSubscription<InterceptedSms>? _smsSubscription;
  Timer? _timeoutTimer;

  @override
  RechargeFlowState build() {
    _permissionService = getIt<MobileMoneyPermissionService>();
    _simSelectorService = getIt<SimSelectorService>();
    _dialerService = getIt<UssdDialerService>();
    _smsService = getIt<SmsInterceptorService>();
    _walletRepository = getIt<WalletRepository>();

    ref.onDispose(() {
      _smsSubscription?.cancel();
      _timeoutTimer?.cancel();
      _smsService.stopListening();
    });

    return RechargeFlowState.initial();
  }

  void selectOperator(MobileOperator operator) {
    state = state.copyWith(operator: operator, step: RechargeStep.enterAmount, clearError: true);
  }

  void backToOperatorSelection() => state = RechargeFlowState.initial();

  Future<void> startRecharge(int amountFcfa) async {
    if (amountFcfa < MobileMoneyConfig.minimumRechargeFcfa) {
      state = state.copyWith(
        errorMessage: 'Montant minimum : ${MobileMoneyConfig.minimumRechargeFcfa} FCFA.',
      );
      return;
    }
    final operator = state.operator;
    if (operator == null) {
      state = state.copyWith(step: RechargeStep.selectOperator);
      return;
    }

    state = state.copyWith(amountFcfa: amountFcfa, step: RechargeStep.requestingPermission, clearError: true);

    final permissionStatus = await _permissionService.requestAll();

    switch (permissionStatus) {
      case MobileMoneyPermissionStatus.granted:
        await _resolveSim();
      case MobileMoneyPermissionStatus.denied:
        state = state.copyWith(
          step: RechargeStep.permissionDenied,
          errorMessage: 'Les permissions SMS et Appel sont nécessaires pour recharger. Réessayez pour les autoriser.',
        );
      case MobileMoneyPermissionStatus.permanentlyDenied:
        state = state.copyWith(
          step: RechargeStep.permissionPermanentlyDenied,
          errorMessage: 'Permissions bloquées définitivement. Ouvrez les réglages de l\'app.',
        );
    }
  }

  Future<void> openSystemSettings() => _permissionService.openSystemSettings();

  Future<void> _resolveSim() async {
    final sims = await _simSelectorService.getAvailableSims();
    if (sims.length <= 1) {
      final subscriptionId = sims.isNotEmpty ? sims.first.subscriptionId : 0;
      await _dialAndListen(subscriptionId);
      return;
    }
    state = state.copyWith(step: RechargeStep.selectSim, availableSims: sims);
  }

  Future<void> selectSim(SimInfo sim) => _dialAndListen(sim.subscriptionId);

  Future<void> _dialAndListen(int subscriptionId) async {
    final operator = state.operator;
    final amountFcfa = state.amountFcfa;
    if (operator == null || amountFcfa == null) return;

    state = state.copyWith(step: RechargeStep.dialing);

    final config = MobileMoneyConfig.operators[operator]!;
    final ussdCode = config.buildUssdCode(
      merchantNumber: MobileMoneyConfig.merchantPhoneNumber,
      amountFcfa: amountFcfa,
    );

    final dialed = await _dialerService.dial(ussdCode, subscriptionId: subscriptionId);
    if (!dialed) {
      state = state.copyWith(
        step: RechargeStep.failed,
        errorMessage: 'Impossible de lancer la composition automatique. Réessayez depuis le début.',
      );
      return;
    }

    state = state.copyWith(step: RechargeStep.waitingForSms);

    final stream = await _smsService.startListening(subscriptionId: subscriptionId);

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(MobileMoneyConfig.smsWaitTimeout, () {
      if (state.step == RechargeStep.waitingForSms) {
        _smsSubscription?.cancel();
        _smsService.stopListening();
        state = state.copyWith(
          step: RechargeStep.failed,
          errorMessage: 'Aucune confirmation reçue. Vérifiez la transaction puis réessayez depuis le début.',
        );
      }
    });

    _smsSubscription?.cancel();
    _smsSubscription = stream.listen((sms) {
      if (sms.sender.contains(config.smsSenderId)) {
        _timeoutTimer?.cancel();
        _submitSms(sms.body);
      }
    });
  }

  Future<void> _submitSms(String smsText) async {
    await _smsSubscription?.cancel();
    await _smsService.stopListening();
    state = state.copyWith(step: RechargeStep.submitting, clearError: true);

    try {
      final result = await _walletRepository.rechargeWithSms(smsText);
      state = state.copyWith(
        step: RechargeStep.success,
        amountCreditedFcfa: result.amountCreditedFcfa,
        newBalanceFcfa: result.newBalanceFcfa,
      );
    } on WalletException catch (error) {
      state = state.copyWith(step: RechargeStep.failed, errorMessage: error.publicMessage);
    }
  }

  void reset() {
    _smsSubscription?.cancel();
    _timeoutTimer?.cancel();
    _smsService.stopListening();
    state = RechargeFlowState.initial();
  }
}

final rechargeFlowControllerProvider =
    NotifierProvider<RechargeFlowController, RechargeFlowState>(RechargeFlowController.new);
