import 'dart:typed_data';

class TicketTotpCode {
  const TicketTotpCode({
    required this.code6Digits,
    required this.secondsRemaining,
    required this.validFromUnix,
    required this.stepSeconds,
    required this.qrSignatureBytes,
  });

  factory TicketTotpCode.fromJson(Map<String, dynamic> json) {
    final sigHex = json['qr_signature_hex'] as String? ?? '';
    final sigBytes = Uint8List(8);
    for (var i = 0; i < 8 && i * 2 + 1 < sigHex.length; i++) {
      sigBytes[i] = int.parse(sigHex.substring(i * 2, i * 2 + 2), radix: 16);
    }

    return TicketTotpCode(
      code6Digits: json['code_6_digits'] as String? ?? '000000',
      secondsRemaining: json['seconds_remaining'] as int? ?? 0,
      validFromUnix: json['valid_from_unix'] as int? ?? 0,
      stepSeconds: json['step_seconds'] as int? ?? 30,
      qrSignatureBytes: sigBytes,
    );
  }

  final String code6Digits;
  final int secondsRemaining;
  final int validFromUnix;
  final int stepSeconds;

  /// 8 bytes — signature émise par le serveur, jamais calculée
  /// localement. Voir backend_addendum/qr_signature_totp_endpoint.py.
  final Uint8List qrSignatureBytes;
}
