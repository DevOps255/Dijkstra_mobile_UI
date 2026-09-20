import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../domain/wallet_balance.dart';
import '../domain/wallet_exception.dart';
import '../domain/wallet_transaction_item.dart';

class RechargeResult {
  const RechargeResult({
    required this.amountCreditedFcfa,
    required this.newBalanceFcfa,
  });
  final int amountCreditedFcfa;
  final int newBalanceFcfa;
}

@lazySingleton
class WalletRepository {
  WalletRepository(this._dio);
  final Dio _dio;

  Future<WalletBalance> fetchBalance() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/wallet/balance');
      return WalletBalance.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<WalletTransactionItem>> fetchTransactions({int limit = 50}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/wallet/transactions',
        queryParameters: {'limit': limit},
      );
      final raw = response.data ?? [];
      return raw
          .map((e) => WalletTransactionItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<RechargeResult> rechargeWithSms(String smsText) async {
    final trimmed = smsText.trim();
    if (trimmed.length < 10) {
      throw const WalletException('SMS de confirmation invalide.');
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/payments/recharge',
        data: {'sms_text': trimmed, 'platform': 'android'},
      );
      final data = response.data ?? const {};
      return RechargeResult(
        amountCreditedFcfa: data['amount_credited_fcfa'] as int? ?? 0,
        newBalanceFcfa: data['new_balance_fcfa'] as int? ?? 0,
      );
    } on DioException catch (error) {
      throw _mapError(error, contextRecharge: true);
    }
  }

  WalletException _mapError(DioException error, {bool contextRecharge = false}) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return WalletException.network();
    }
    final status = error.response?.statusCode;
    if (status == 429) {
      final retryAfter = error.response?.headers.value('Retry-After');
      return WalletException(
        retryAfter != null
            ? 'Trop de tentatives. Réessayez dans ${retryAfter}s.'
            : 'Trop de tentatives. Réessayez plus tard.',
      );
    }
    if (contextRecharge && (status == 422 || status == 409)) {
      return WalletException.rechargeNotRecognized();
    }
    final detail = error.response?.data is Map
        ? (error.response?.data as Map)['detail'] as String?
        : null;
    if (detail != null && detail.isNotEmpty) return WalletException(detail);
    return WalletException.generic();
  }
}
