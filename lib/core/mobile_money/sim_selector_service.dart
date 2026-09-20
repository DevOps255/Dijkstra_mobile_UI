import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import 'sim_info.dart';

@lazySingleton
class SimSelectorService {
  static const MethodChannel _channel =
      MethodChannel('bus.campus/mobile_money');

  Future<List<SimInfo>> getAvailableSims() async {
    if (!Platform.isAndroid) return const [];

    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getAvailableSims',
      );
      if (result == null) return const [];

      return result
          .map((entry) => SimInfo.fromMap(entry as Map<dynamic, dynamic>))
          .toList();
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }
}
