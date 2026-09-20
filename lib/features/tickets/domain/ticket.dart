import 'package:equatable/equatable.dart';

class Ticket extends Equatable {
  const Ticket({
    required this.id,
    required this.tripId,
    required this.lineId,
    required this.status,
    required this.lineName,
    required this.boardingStopId,
    required this.boardingStopName,
    required this.alightingStopId,
    required this.alightingStopName,
    required this.validFrom,
    required this.validUntil,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['ticket_id'] as String? ?? json['id'] as String? ?? '',
      tripId: json['trip_id'] as String? ?? '',
      lineId: json['line_id'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      lineName: json['line_name'] as String? ?? '',
      boardingStopId: json['boarding_stop_id'] as String? ?? '',
      boardingStopName: json['boarding_stop_name'] as String? ?? '',
      alightingStopId: json['alighting_stop_id'] as String? ?? '',
      alightingStopName: json['alighting_stop_name'] as String? ?? '',
      validFrom: DateTime.tryParse(json['valid_from'] as String? ?? '') ?? DateTime.now(),
      validUntil: DateTime.tryParse(json['valid_until'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String tripId;
  final String lineId;
  final String status;
  final String lineName;
  final String boardingStopId;
  final String boardingStopName;
  final String alightingStopId;
  final String alightingStopName;
  final DateTime validFrom;
  final DateTime validUntil;

  bool get isValid => status == 'valid';
  bool get isUsed => status == 'used';

  @override
  List<Object?> get props => [id, status];
}
