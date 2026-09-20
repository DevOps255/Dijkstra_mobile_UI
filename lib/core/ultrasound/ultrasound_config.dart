/// Constantes du protocole ultrason — DOIVENT rester strictement
/// synchronisées avec native/ultrasound_fsk/ultrasound_fsk.h et .cpp.
/// Toute modification ici sans modification symétrique côté C++
/// casse silencieusement le protocole.
abstract final class UltrasoundConfig {
  UltrasoundConfig._();

  static const int sampleRate = 44100;
  static const double freqBit0 = 18500.0;
  static const double freqBit1 = 19500.0;

  /// 132 échantillons à 44100Hz ≈ 2,993ms/bit. Choisi pour une
  /// trame complète d'environ 1,5s plutôt que ~6s (512 échantillons
  /// d'origine). Contrepartie : résolution fréquentielle Goertzel
  /// ≈ 334Hz contre 1000Hz de séparation utile entre freqBit0 et
  /// freqBit1 — marge réduite (≈3x) face au bruit ambiant. À
  /// valider empiriquement sur appareil réel dans un bus ; si le
  /// taux d'erreur est trop élevé en conditions réelles, remonter
  /// cette valeur (256 ≈ 5,8ms/bit est un compromis intermédiaire).
  static const int symbolSamples = 132;

  static const int preambleBits = 32;
  static const int syncWordBits = 16;

  /// Taille de la trame logique en bytes — doit être identique à
  /// ULTRASOUND_FRAME_LOGICAL_BYTES côté C++.
  static const int frameLogicalBytes = 33;

  static const int frameTypeBeacon = 1;
  static const int frameTypeConfirmation = 2;

  /// Durée totale d'une trame complète, calculée depuis les
  /// constantes ci-dessus (préambule + sync + 66 nibbles x 7 bits
  /// Hamming), pour affichage/diagnostic uniquement.
  static Duration get frameDuration {
    const hammingBitsTotal = (frameLogicalBytes * 2) * 7;
    const totalBits = preambleBits + syncWordBits + hammingBitsTotal;
    final microseconds =
        (totalBits * symbolSamples / sampleRate * 1000000).round();
    return Duration(microseconds: microseconds);
  }
}
