import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../domain/wallet_balance.dart';

/// `GET /wallet/balance` — endpoint explicitement référencé dans le
/// commentaire du router d'achat de ticket de L34A
/// (`"solde_restant_fcfa": None, # Chargé séparément via GET /wallet/balance`)
/// mais jamais codé dans les leçons fournies. Contrairement à
/// `check-email` ou `notifications`, ce n'est donc pas une invention
/// de ma part — c'est un contrat déjà annoncé côté backend, qu'il
/// reste à implémenter avec le même corps que retournent
/// `credit_wallet` / `debit_wallet_for_ticket` (L34A) :
/// `{"balance_minor_units": int}`.
@lazySingleton
class WalletRepository {
  WalletRepository(this._dio);

  final Dio _dio;

  Future<WalletBalance?> fetchBalance() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/wallet/balance',
      );
      if (response.data == null) return null;
      return WalletBalance.fromJson(response.data!);
    } on DioException {
      // Dégradation silencieuse — l'appelant affiche un état
      // "solde indisponible" plutôt qu'une erreur bloquante. Le
      // portefeuille n'est jamais critique pour la navigation.
      return null;
    }
  }
}
