import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/di/injection.dart';
import '../../../core/network/api_config.dart';
import '../../../core/storage/auth_session_store.dart';

enum GpsConnectionStatus { connecting, connected, disconnected, reconnecting, failed }

class GpsSocketEvent {
  const GpsSocketEvent({required this.type, required this.data});
  final String type;
  final Map<String, dynamic> data;
}

const _maxReconnectAttempts = 8;
const _baseReconnectDelay = Duration(seconds: 1);
const _maxReconnectDelay = Duration(seconds: 30);

/// Traduction Dart du client WebSocket TypeScript de la Leçon 37B —
/// même logique de reconnexion avec backoff exponentiel plafonné,
/// même distinction entre fermeture volontaire (codes 4001/4003,
/// jamais de reconnexion) et fermeture accidentelle.
@injectable
class GpsWebSocketClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _destroyed = false;

  String? _lineId;
  String? _ticketId;

  final _eventController = StreamController<GpsSocketEvent>.broadcast();
  final _statusController = StreamController<GpsConnectionStatus>.broadcast();

  Stream<GpsSocketEvent> get events => _eventController.stream;
  Stream<GpsConnectionStatus> get status => _statusController.stream;

  void connect({required String lineId, required String ticketId}) {
    if (_destroyed) {
      throw StateError('GpsWebSocketClient.connect : client détruit.');
    }
    _lineId = lineId;
    _ticketId = ticketId;
    _reconnectAttempts = 0;
    _doConnect();
  }

  void _doConnect() {
    if (_destroyed || _lineId == null || _ticketId == null) return;

    _statusController.add(GpsConnectionStatus.connecting);

    final token = getIt<AuthSessionStore>().accessToken ?? '';
    final wsScheme = ApiConfig.baseUrl.startsWith('https') ? 'wss' : 'ws';
    final host = ApiConfig.baseUrl.replaceFirst(RegExp(r'^https?'), '');
    final uri = Uri.parse('$wsScheme$host/ws/line/$_lineId'
        '?token=${Uri.encodeQueryComponent(token)}'
        '&ticket_id=${Uri.encodeQueryComponent(_ticketId!)}');

    try {
      _channel = WebSocketChannel.connect(uri);
    } catch (_) {
      _scheduleReconnect();
      return;
    }

    _subscription = _channel!.stream.listen(
      (raw) {
        _reconnectAttempts = 0;
        _statusController.add(GpsConnectionStatus.connected);

        try {
          final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
          final type = decoded['type'] as String?;
          if (type == null) return;
          if (type == 'pong') return;
          _eventController.add(GpsSocketEvent(
            type: type,
            data: (decoded['data'] as Map<String, dynamic>?) ?? const {},
          ));
        } catch (_) {
          // Message non-JSON — ignoré, ne casse jamais le flux.
        }
      },
      onError: (_) => _handleClosure(),
      onDone: _handleClosure,
      cancelOnError: false,
    );

    _statusController.add(GpsConnectionStatus.connected);
  }

  void _handleClosure() {
    if (_destroyed) return;
    final closeCode = _channel?.closeCode;
    if (closeCode == 4001 || closeCode == 4003) {
      _statusController.add(GpsConnectionStatus.failed);
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_destroyed) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _statusController.add(GpsConnectionStatus.failed);
      return;
    }

    _statusController.add(GpsConnectionStatus.reconnecting);
    _reconnectAttempts++;

    final delayMs = (_baseReconnectDelay.inMilliseconds * (1 << (_reconnectAttempts - 1)))
        .clamp(0, _maxReconnectDelay.inMilliseconds);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), _doConnect);
  }

  void disconnect() {
    _destroyed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _statusController.add(GpsConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _statusController.close();
  }
}
