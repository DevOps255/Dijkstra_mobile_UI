import 'package:equatable/equatable.dart';

enum WalletTransactionType { recharge, purchase, refund, unknown }
enum WalletTransactionDirection { credit, debit }

class WalletTransactionItem extends Equatable {
  const WalletTransactionItem({
    required this.id,
    required this.type,
    required this.direction,
    required this.amountMinorUnits,
    required this.balanceAfterMinorUnits,
    required this.reference,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransactionItem.fromJson(Map<String, dynamic> json) {
    return WalletTransactionItem(
      id: json['id'] as String? ?? '',
      type: _parseType(json['type'] as String?),
      direction: (json['direction'] as String?) == 'debit'
          ? WalletTransactionDirection.debit
          : WalletTransactionDirection.credit,
      amountMinorUnits: json['amount_minor_units'] as int? ?? 0,
      balanceAfterMinorUnits: json['balance_after_minor_units'] as int? ?? 0,
      reference: json['reference'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final WalletTransactionType type;
  final WalletTransactionDirection direction;
  final int amountMinorUnits;
  final int balanceAfterMinorUnits;
  final String? reference;
  final String? description;
  final DateTime createdAt;

  int get amountFcfa => amountMinorUnits ~/ 100;

  static WalletTransactionType _parseType(String? raw) {
    switch (raw) {
      case 'recharge': return WalletTransactionType.recharge;
      case 'purchase': return WalletTransactionType.purchase;
      case 'refund': return WalletTransactionType.refund;
      default: return WalletTransactionType.unknown;
    }
  }

  @override
  List<Object?> get props => [id, type, direction, amountMinorUnits, createdAt];
}
