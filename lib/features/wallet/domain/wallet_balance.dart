import 'package:equatable/equatable.dart';

class WalletBalance extends Equatable {
  const WalletBalance({required this.balanceMinorUnits});

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      balanceMinorUnits: json['balance_minor_units'] as int? ?? 0,
    );
  }

  factory WalletBalance.zero() => const WalletBalance(balanceMinorUnits: 0);

  final int balanceMinorUnits;
  int get fcfa => balanceMinorUnits ~/ 100;

  @override
  List<Object?> get props => [balanceMinorUnits];
}
