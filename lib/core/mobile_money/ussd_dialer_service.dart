import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class UssdDialerService {
  static const MethodChannel _channel =
      MethodChannel('bus.campus/mobile_money');

  Future<bool> dial(String ussdCode, {required int subscriptionId}) async {
    if (!Platform.isAndroid) return false;

    try {
      await _channel.invokeMethod('dialUssd', {
        'code': ussdCode,
        'subscriptionId': subscriptionId,
      });
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
