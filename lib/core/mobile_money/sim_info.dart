import 'package:equatable/equatable.dart';

class SimInfo extends Equatable {
  const SimInfo({
    required this.subscriptionId,
    required this.displayName,
    required this.carrierName,
    required this.slotIndex,
  });

  factory SimInfo.fromMap(Map<dynamic, dynamic> map) {
    return SimInfo(
      subscriptionId: map['subscriptionId'] as int? ?? -1,
      displayName: map['displayName'] as String? ?? '',
      carrierName: map['carrierName'] as String? ?? '',
      slotIndex: map['slotIndex'] as int? ?? 0,
    );
  }

  final int subscriptionId;
  final String displayName;
  final String carrierName;
  final int slotIndex;

  @override
  List<Object?> get props => [subscriptionId, slotIndex];
}
