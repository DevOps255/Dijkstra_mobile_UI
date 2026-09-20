import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../data/ticket_repository.dart';
import '../domain/ticket.dart';
import '../domain/ticket_exception.dart';

class TicketListState {
  const TicketListState({
    required this.tickets,
    required this.isLoading,
    this.errorMessage,
  });

  factory TicketListState.initial() =>
      const TicketListState(tickets: [], isLoading: true);

  final List<Ticket> tickets;
  final bool isLoading;
  final String? errorMessage;

  TicketListState copyWith({
    List<Ticket>? tickets,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TicketListState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TicketListController extends Notifier<TicketListState> {
  late final TicketRepository _repository;

  @override
  TicketListState build() {
    _repository = getIt<TicketRepository>();
    Future.microtask(refresh);
    return TicketListState.initial();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tickets = await _repository.fetchMyTickets();
      state = state.copyWith(tickets: tickets, isLoading: false);
    } on TicketException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.publicMessage);
    }
  }
}

final ticketListControllerProvider =
    NotifierProvider<TicketListController, TicketListState>(TicketListController.new);
