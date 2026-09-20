import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../domain/ticket.dart';
import '../domain/ticket_exception.dart';
import '../domain/ticket_totp_code.dart';

@lazySingleton
class TicketRepository {
  TicketRepository(this._dio);
  final Dio _dio;

  Future<List<Ticket>> fetchMyTickets() async {
    try {
      final response = await _dio.get<List<dynamic>>('/tickets/mine');
      final raw = response.data ?? [];
      return raw.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<TicketTotpCode> fetchTotpCode(String ticketId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/tickets/$ticketId/totp-code');
      return TicketTotpCode.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Valide le ticket côté serveur. C'est la seule opération qui
  /// marque réellement le ticket comme 'used' — l'émission de la
  /// confirmation ultrason est un signal complémentaire pour la
  /// future réception hors-ligne côté chauffeur, jamais l'unique
  /// voie de validation.
  Future<void> validateTicket({
    required String ticketId,
    required String tripId,
    required String totpCode,
    required int timestampUnix,
    String method = 'ultrasonic',
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/tickets/$ticketId/validate',
        data: {
          'totp_code': totpCode,
          'trip_id': tripId,
          'timestamp_unix': timestampUnix,
          'validation_method': method,
        },
      );
    } on DioException catch (error) {
      // 409 = déjà validé — traité comme un succès par l'appelant
      // (idempotent, cf. Leçon 39B : si le ticket est déjà used,
      // l'étudiant est de toute façon dans le bus).
      if (error.response?.statusCode == 409) return;
      throw _mapError(error, contextValidate: true);
    }
  }

  TicketException _mapError(DioException error, {bool contextValidate = false}) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return TicketException.network();
    }
    if (contextValidate && error.response?.statusCode == 422) {
      return TicketException.invalidTicket();
    }
    final detail = error.response?.data is Map
        ? (error.response?.data as Map)['detail'] as String?
        : null;
    if (detail != null && detail.isNotEmpty) return TicketException(detail);
    return TicketException.generic();
  }
}
