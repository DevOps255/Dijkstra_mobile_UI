import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import 'intercepted_sms.dart';

@lazySingleton
class SmsInterceptorService {
  static const MethodChannel _methodChannel =
      MethodChannel('bus.campus/mobile_money');
  static const EventChannel _eventChannel =
      EventChannel('bus.campus/mobile_money/sms_stream');

  StreamSubscription<dynamic>? _rawSubscription;
  StreamController<InterceptedSms>? _controller;

  Future<Stream<InterceptedSms>> startListening({
    required int subscriptionId,
  }) async {
    if (!Platform.isAndroid) {
      return const Stream.empty();
    }

    try {
      await _methodChannel.invokeMethod('startSmsListening', {
        'subscriptionId': subscriptionId,
      });
    } catch (_) {}

    await _controller?.close();
    _controller = StreamController<InterceptedSms>.broadcast();

    _rawSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final sender = event['sender'] as String? ?? '';
          final body = event['body'] as String? ?? '';
          if (body.isNotEmpty) {
            _controller?.add(InterceptedSms(sender: sender, body: body));
          }
        }
      },
      onError: (_) {},
      cancelOnError: false,
    );

    return _controller!.stream;
  }

  Future<void> stopListening() async {
    await _rawSubscription?.cancel();
    _rawSubscription = null;
    await _controller?.close();
    _controller = null;

    if (Platform.isAndroid) {
      try {
        await _methodChannel.invokeMethod('stopSmsListening');
      } catch (_) {}
    }
  }
}
