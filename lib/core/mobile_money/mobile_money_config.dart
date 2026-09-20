import 'package:flutter/material.dart';

enum MobileOperator { mixx, flooz }

class OperatorConfig {
  const OperatorConfig({
    required this.displayName,
    required this.logoAsset,
    required this.smsSenderId,
    required this.ussdTemplate,
    required this.brandColor,
  });

  final String displayName;
  final String logoAsset;
  final String smsSenderId;
  final String ussdTemplate;
  final Color brandColor;

  String buildUssdCode({
    required String merchantNumber,
    required int amountFcfa,
  }) {
    return ussdTemplate
        .replaceAll('{number}', merchantNumber)
        .replaceAll('{amount}', amountFcfa.toString());
  }
}

abstract final class MobileMoneyConfig {
  static const String merchantPhoneNumber = 'XXXXXXXX'; // <- A REMPLACER

  static const Map<MobileOperator, OperatorConfig> operators = {
    MobileOperator.mixx: OperatorConfig(
      displayName: 'Mixx by Yas',
      logoAsset: 'assets/images/mixx_logo.png',
      smsSenderId: '905',
      ussdTemplate: '*145*1*1*{number}*{amount}*1#',
      brandColor: Color(0xFF002E6D),
    ),
    MobileOperator.flooz: OperatorConfig(
      displayName: 'Flooz',
      logoAsset: 'assets/images/flooz_logo.png',
      smsSenderId: '205',
      ussdTemplate: '*101*1*{number}*{amount}*1#',
      brandColor: Color(0xFFF97316),
    ),
  };

  static const int minimumRechargeFcfa = 100;
  static const Duration smsWaitTimeout = Duration(seconds: 90);

  const MobileMoneyConfig._();
}
