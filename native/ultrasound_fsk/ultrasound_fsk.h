#ifndef ULTRASOUND_FSK_H
#define ULTRASOUND_FSK_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Module FSK bidirectionnel, avec intégrité (CRC16) et correction
 * d'erreur légère (Hamming 7,4) — utilisé par le chauffeur (émission
 * du beacon de trajet) ET par l'étudiant (réception du beacon, puis
 * émission de sa confirmation de ticket). Même binaire des deux
 * côtés — le rôle est déterminé par quelles fonctions Dart appelle.
 *
 * TRAME LOGIQUE (avant correction d'erreur), 33 bytes = 264 bits :
 *   byte 0        : frame_type   (1 = beacon chauffeur, 2 = confirmation étudiant)
 *   bytes 1-2     : sequence     (uint16 big-endian, compteur par émetteur)
 *   bytes 3-18    : subject_id   (UUID 16 bytes — trip_id ou ticket_id)
 *   bytes 19-22   : timestamp_unix (uint32 big-endian)
 *   bytes 23-30   : proof        (8 bytes — HMAC device chauffeur, OU
 *                                 signature ISSUE PAR LE SERVEUR pour
 *                                 une confirmation étudiant. Jamais
 *                                 calculée sur l'appareil qui émet.)
 *   bytes 31-32   : crc16        (CRC-16-CCITT sur les bytes 0-30)
 *
 * SUR LE FIL, après [PREAMBLE 32 bits][SYNC WORD 16 bits] :
 * chaque nibble (4 bits) de la trame logique ci-dessus est encodé en
 * un mot de Hamming(7,4) de 7 bits avant modulation FSK. 33 bytes =
 * 66 nibbles = 66 x 7 = 462 bits transmis pour la donnée, plus 48
 * bits de synchronisation fixe (non codés, cherchés directement).
 *
 * Le CRC est vérifié à l'INTÉRIEUR du décodeur C++ : une trame dont
 * le CRC ne correspond pas est un bruit de transmission, pas une
 * fraude — elle est silencieusement écartée (retour 0), jamais
 * remontée à Dart comme une trame "reçue mais invalide". La
 * vérification du champ `proof` (authenticité) est de la
 * responsabilité de l'appelant Dart, qui seul connaît le manifeste
 * ou la clé pertinente selon le frame_type.
 */

#define ULTRASOUND_FRAME_LOGICAL_BYTES 33

void* ultrasound_fsk_create(
    int32_t sample_rate,
    double freq_bit0,
    double freq_bit1,
    int32_t symbol_samples
);

void ultrasound_fsk_destroy(void* ctx);

/**
 * Encode une trame logique de ULTRASOUND_FRAME_LOGICAL_BYTES bytes
 * exactement. Applique Hamming(7,4) en interne — l'appelant ne
 * fournit que la trame logique déjà construite (frame_type, sequence,
 * subject_id, timestamp, proof, crc16), jamais les bits protégés.
 *
 * Retourne le nombre de samples écrits, ou -1 en cas d'erreur
 * (paramètres invalides, data_len != ULTRASOUND_FRAME_LOGICAL_BYTES,
 * ou output_len insuffisant).
 */
int32_t ultrasound_fsk_encode_frame(
    void* ctx,
    const uint8_t* frame_logical_bytes,
    float* output,
    int32_t output_len
);

/**
 * Nombre de samples nécessaires pour encoder une trame complète
 * (préambule + sync word + données protégées par Hamming).
 */
int32_t ultrasound_fsk_required_samples_for_frame(void* ctx);

/**
 * Décode UN bit FSK dominant depuis une fenêtre de symbol_samples
 * échantillons (Goertzel, O(N) par fréquence cible). Retourne 1
 * (bit écrit dans output_bit[0]) ou 0 (signal trop faible).
 */
int32_t ultrasound_fsk_decode_bit(
    void* ctx,
    const float* audio_input,
    int32_t input_len,
    uint8_t* output_bit
);

void* ultrasound_frame_decoder_create(void* fsk_ctx);
void ultrasound_frame_decoder_destroy(void* decoder);
void ultrasound_frame_decoder_reset(void* decoder);

/**
 * Alimente le décodeur avec un bit. Le décodeur gère en interne :
 * recherche du préambule -> recherche du mot de synchronisation ->
 * accumulation des blocs de Hamming(7,4) avec correction d'un bit
 * d'erreur par nibble -> vérification CRC16.
 *
 * Retourne ULTRASOUND_FRAME_LOGICAL_BYTES (33) si une trame complète
 * ET dont le CRC est valide a été reçue (écrite dans output_frame).
 * Retourne 0 si la trame n'est pas encore complète, OU si une trame
 * complète a été reçue mais que son CRC ne correspond pas (bruit —
 * le décodeur se réinitialise automatiquement dans ce cas et
 * reprend la recherche du préambule).
 * Retourne -1 en cas d'erreur de paramètres.
 */
int32_t ultrasound_frame_decoder_feed_bit(
    void* decoder,
    uint8_t bit,
    uint8_t* output_frame,
    int32_t output_len
);

#ifdef __cplusplus
}
#endif

#endif
