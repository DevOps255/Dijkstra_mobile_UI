import 'package:equatable/equatable.dart';

class InterceptedSms extends Equatable {
  const InterceptedSms({required this.sender, required this.body});

  final String sender;
  final String body;

  @override
  List<Object?> get props => [sender, body];
}
