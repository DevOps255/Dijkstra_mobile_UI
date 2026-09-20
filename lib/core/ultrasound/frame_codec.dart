import 'dart:typed_data';

import 'ultrasound_config.dart';

/// Représentation Dart de la trame logique de 33 bytes échangée
/// sur le canal ultrason, AVANT correction Hamming (qui est gérée
/// entièrement côté C++, invisible depuis Dart).
///
/// [proof] porte :
/// - pour un beacon chauffeur : les 8 premiers bytes du HMAC device
///   du chauffeur (calculé et signé côté app chauffeur, avec sa
///   propre clé — jamais transmise ailleurs)
/// - pour une confirmation étudiant : la signature ISSUE PAR LE
///   SERVEUR au moment de la génération du code TOTP courant.
///   L'app étudiante ne calcule JAMAIS cette signature elle-même —
///   elle relaie uniquement ce que le serveur a déjà signé. Voir
///   GET /tickets/{id}/totp-code qui doit retourner ce champ.
class LogicalFrame {
  const LogicalFrame({
    required this.frameType,
    required this.sequence,
    required this.subjectIdBytes,
    required this.timestampUnix,
    required this.proof,
  })  : assert(subjectIdBytes.length == 16,
            'subjectIdBytes doit faire exactement 16 bytes (UUID).'),
        assert(proof.length == 8,
            'proof doit faire exactement 8 bytes.');

  final int frameType;
  final int sequence;
  final Uint8List subjectIdBytes;
  final int timestampUnix;
  final Uint8List proof;

  /// Encode la trame logique en 33 bytes, CRC16 inclus (les 2
  /// derniers bytes). Le CRC est calculé ici en Dart, avec le même
  /// polynôme et la même initialisation que le module C++ — les
  /// deux implémentations DOIVENT rester en accord bit pour bit,
  /// sinon chaque trame émise depuis Dart sera rejetée par le
  /// décodeur C++ (qui, lui, vérifie le CRC en interne).
  Uint8List toBytes() {
    final buffer = Uint8List(UltrasoundConfig.frameLogicalBytes);
    var offset = 0;

    buffer[offset++] = frameType & 0xFF;

    buffer[offset++] = (sequence >> 8) & 0xFF;
    buffer[offset++] = sequence & 0xFF;

    buffer.setRange(offset, offset + 16, subjectIdBytes);
    offset += 16;

    buffer[offset++] = (timestampUnix >> 24) & 0xFF;
    buffer[offset++] = (timestampUnix >> 16) & 0xFF;
    buffer[offset++] = (timestampUnix >> 8) & 0xFF;
    buffer[offset++] = timestampUnix & 0xFF;

    buffer.setRange(offset, offset + 8, proof);
    offset += 8;

    final crc = crc16Ccitt(buffer.sublist(0, offset));
    buffer[offset++] = (crc >> 8) & 0xFF;
    buffer[offset++] = crc & 0xFF;

    return buffer;
  }

  /// Parse une trame de 33 bytes déjà validée par le CRC (le
  /// décodeur C++ ne remonte jamais une trame dont le CRC est
  /// invalide — cette fonction ne revérifie donc pas le CRC).
  ///
  /// Retourne null si la longueur est incorrecte.
  static LogicalFrame? fromBytes(Uint8List bytes) {
    if (bytes.length != UltrasoundConfig.frameLogicalBytes) return null;

    var offset = 0;
    final frameType = bytes[offset++];

    final sequence = (bytes[offset] << 8) | bytes[offset + 1];
    offset += 2;

    final subjectIdBytes = bytes.sublist(offset, offset + 16);
    offset += 16;

    final timestampUnix = (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    offset += 4;

    final proof = bytes.sublist(offset, offset + 8);
    offset += 8;

    return LogicalFrame(
      frameType: frameType,
      sequence: sequence,
      subjectIdBytes: Uint8List.fromList(subjectIdBytes),
      timestampUnix: timestampUnix,
      proof: Uint8List.fromList(proof),
    );
  }

  /// CRC-16-CCITT, polynôme 0x1021, initialisation 0xFFFF — doit
  /// produire EXACTEMENT le même résultat que crc16_ccitt() dans
  /// ultrasound_fsk.cpp pour les mêmes bytes en entrée.
  static int crc16Ccitt(List<int> data) {
    var crc = 0xFFFF;
    for (final byte in data) {
      crc ^= (byte & 0xFF) << 8;
      for (var b = 0; b < 8; b++) {
        if (crc & 0x8000 != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc;
  }
}

/// Convertit une chaîne UUID standard ("xxxxxxxx-xxxx-...") en 16
/// bytes bruts, pour insertion dans une trame.
Uint8List uuidStringToBytes(String uuid) {
  final hex = uuid.replaceAll('-', '');
  if (hex.length != 32) {
    throw ArgumentError.value(uuid, 'uuid', 'UUID invalide.');
  }
  final bytes = Uint8List(16);
  for (var i = 0; i < 16; i++) {
    bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return bytes;
}

/// Convertit 16 bytes bruts en chaîne UUID standard.
String bytesToUuidString(Uint8List bytes) {
  if (bytes.length != 16) {
    throw ArgumentError.value(bytes, 'bytes', '16 bytes attendus.');
  }
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20, 32)}';
}
