import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet_balance.dart';
import '../domain/wallet_exception.dart';
import '../domain/wallet_transaction_item.dart';

class WalletState {
  const WalletState({
    required this.balance,
    required this.transactions,
    required this.isLoadingBalance,
    required this.isLoadingTransactions,
    this.errorMessage,
  });

  factory WalletState.initial() => WalletState(
        balance: WalletBalance.zero(),
        transactions: const [],
        isLoadingBalance: true,
        isLoadingTransactions: true,
      );

  final WalletBalance balance;
  final List<WalletTransactionItem> transactions;
  final bool isLoadingBalance;
  final bool isLoadingTransactions;
  final String? errorMessage;

  WalletState copyWith({
    WalletBalance? balance,
    List<WalletTransactionItem>? transactions,
    bool? isLoadingBalance,
    bool? isLoadingTransactions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      isLoadingBalance: isLoadingBalance ?? this.isLoadingBalance,
      isLoadingTransactions: isLoadingTransactions ?? this.isLoadingTransactions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class WalletController extends Notifier<WalletState> {
  late final WalletRepository _repository;

  @override
  WalletState build() {
    _repository = getIt<WalletRepository>();
    Future.microtask(_loadAll);
    return WalletState.initial();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadBalance(), _loadTransactions()]);
  }

  Future<void> _loadBalance() async {
    state = state.copyWith(isLoadingBalance: true);
    try {
      final balance = await _repository.fetchBalance();
      state = state.copyWith(balance: balance, isLoadingBalance: false);
    } on WalletException catch (error) {
      state = state.copyWith(isLoadingBalance: false, errorMessage: error.publicMessage);
    }
  }

  Future<void> _loadTransactions() async {
    state = state.copyWith(isLoadingTransactions: true);
    try {
      final transactions = await _repository.fetchTransactions();
      state = state.copyWith(transactions: transactions, isLoadingTransactions: false);
    } on WalletException catch (error) {
      state = state.copyWith(isLoadingTransactions: false, errorMessage: error.publicMessage);
    }
  }

  Future<void> refresh() => _loadAll();
}

final walletControllerProvider =
    NotifierProvider<WalletController, WalletState>(WalletController.new);
