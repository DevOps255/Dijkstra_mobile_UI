#include "ultrasound_fsk.h"

#include <cmath>
#include <cstring>
#include <new>

// ────────────────────────────────────────────────────────────
// CONSTANTES DE TRAME
// ────────────────────────────────────────────────────────────

static const float PI = 3.14159265358979323846f;
static const float TWO_PI = 2.0f * PI;

// Préambule : alternance 10101010 x4 — synchronise l'horloge du récepteur.
static const uint32_t PREAMBLE_PATTERN = 0xAAAAAAAAu; // 32 bits
static const int PREAMBLE_BITS = 32;

// Mot de synchronisation : cherché juste après le préambule pour
// ancrer fermement le début de trame et réduire les faux positifs
// qu'un préambule seul pourrait produire sur un bruit périodique.
static const uint16_t SYNC_WORD = 0xD391u; // 16 bits
static const int SYNC_WORD_BITS = 16;

static const int LOGICAL_BYTES = ULTRASOUND_FRAME_LOGICAL_BYTES; // 33
static const int LOGICAL_NIBBLES = LOGICAL_BYTES * 2;            // 66
static const int HAMMING_BITS_TOTAL = LOGICAL_NIBBLES * 7;       // 462

// ────────────────────────────────────────────────────────────
// CRC-16-CCITT (poly 0x1021, init 0xFFFF) — détection de bruit,
// pas d'authenticité. Implémentation bit à bit, sans table, pour
// rester lisible et facilement auditable.
// ────────────────────────────────────────────────────────────

static uint16_t crc16_ccitt(const uint8_t* data, int32_t len) {
    uint16_t crc = 0xFFFF;
    for (int32_t i = 0; i < len; ++i) {
        crc ^= (uint16_t)data[i] << 8;
        for (int b = 0; b < 8; ++b) {
            if (crc & 0x8000) {
                crc = (uint16_t)((crc << 1) ^ 0x1021);
            } else {
                crc = (uint16_t)(crc << 1);
            }
        }
    }
    return crc;
}

// ────────────────────────────────────────────────────────────
// HAMMING(7,4) — un bit d'erreur corrigé par bloc de 4 bits utiles.
// Convention de position (1-indexée) : p1 p2 d1 p3 d2 d3 d4
// p1 = d1^d2^d4   (positions impaires : 1,3,5,7)
// p2 = d1^d3^d4   (positions 2,3,6,7)
// p3 = d2^d3^d4   (positions 4,5,6,7)
// Les bits sont manipulés individuellement (valeurs 0/1) plutôt que
// packés — cohérent avec le reste du module, et plus simple à
// auditer bit à bit qu'une version optimisée par masques.
// ────────────────────────────────────────────────────────────

static void hamming74_encode(const uint8_t nibble /* 4 bits, LSB..MSB non utilisé : d1..d4 dans nibble>>3..nibble&1 */,
                              uint8_t out7[7]) {
    // nibble est interprété MSB-first : bit3=d1, bit2=d2, bit1=d3, bit0=d4
    uint8_t d1 = (nibble >> 3) & 1;
    uint8_t d2 = (nibble >> 2) & 1;
    uint8_t d3 = (nibble >> 1) & 1;
    uint8_t d4 = nibble & 1;

    uint8_t p1 = d1 ^ d2 ^ d4;
    uint8_t p2 = d1 ^ d3 ^ d4;
    uint8_t p3 = d2 ^ d3 ^ d4;

    out7[0] = p1;
    out7[1] = p2;
    out7[2] = d1;
    out7[3] = p3;
    out7[4] = d2;
    out7[5] = d3;
    out7[6] = d4;
}

/**
 * Décode un mot de 7 bits en un nibble de 4 bits, en corrigeant au
 * plus une erreur de bit via le syndrome. Le syndrome (0-7) désigne
 * la position 1-indexée du bit erroné, 0 signifiant aucune erreur.
 */
static uint8_t hamming74_decode(const uint8_t in7[7]) {
    uint8_t p1 = in7[0], p2 = in7[1], d1 = in7[2];
    uint8_t p3 = in7[3], d2 = in7[4], d3 = in7[5], d4 = in7[6];

    uint8_t s1 = p1 ^ d1 ^ d2 ^ d4;
    uint8_t s2 = p2 ^ d1 ^ d3 ^ d4;
    uint8_t s3 = p3 ^ d2 ^ d3 ^ d4;

    uint8_t syndrome = (uint8_t)(s1 | (s2 << 1) | (s3 << 2));

    uint8_t corrected[7] = {p1, p2, d1, p3, d2, d3, d4};
    if (syndrome != 0 && syndrome <= 7) {
        corrected[syndrome - 1] ^= 1;
    }

    // Ré-extraction après correction éventuelle.
    d1 = corrected[2];
    d2 = corrected[4];
    d3 = corrected[5];
    d4 = corrected[6];

    return (uint8_t)((d1 << 3) | (d2 << 2) | (d3 << 1) | d4);
}

// ────────────────────────────────────────────────────────────
// CONTEXTE FSK
// ────────────────────────────────────────────────────────────

struct FskContext {
    int32_t sample_rate;
    double freq_bit0;
    double freq_bit1;
    int32_t symbol_samples;
    double phase_accumulator;
};

static void generate_tone(FskContext* ctx, double frequency, float* output, int32_t num_samples) {
    const double phase_increment = TWO_PI * frequency / ctx->sample_rate;
    for (int32_t i = 0; i < num_samples; ++i) {
        output[i] = (float)sin(ctx->phase_accumulator);
        ctx->phase_accumulator += phase_increment;
        if (ctx->phase_accumulator >= TWO_PI) {
            ctx->phase_accumulator -= TWO_PI;
        }
    }
}

static void emit_bit(FskContext* ctx, uint8_t bit, float* output, int32_t& write_pos) {
    double freq = (bit == 0) ? ctx->freq_bit0 : ctx->freq_bit1;
    generate_tone(ctx, freq, output + write_pos, ctx->symbol_samples);
    write_pos += ctx->symbol_samples;
}

void* ultrasound_fsk_create(int32_t sample_rate, double freq_bit0, double freq_bit1, int32_t symbol_samples) {
    if (sample_rate <= 0) return nullptr;
    if (freq_bit0 <= 0.0 || freq_bit0 >= sample_rate / 2.0) return nullptr;
    if (freq_bit1 <= 0.0 || freq_bit1 >= sample_rate / 2.0) return nullptr;
    if (freq_bit0 == freq_bit1) return nullptr;
    if (symbol_samples <= 0) return nullptr;

    FskContext* ctx = new (std::nothrow) FskContext();
    if (ctx == nullptr) return nullptr;

    ctx->sample_rate = sample_rate;
    ctx->freq_bit0 = freq_bit0;
    ctx->freq_bit1 = freq_bit1;
    ctx->symbol_samples = symbol_samples;
    ctx->phase_accumulator = 0.0;
    return ctx;
}

void ultrasound_fsk_destroy(void* ctx_ptr) {
    if (ctx_ptr == nullptr) return;
    delete static_cast<FskContext*>(ctx_ptr);
}

int32_t ultrasound_fsk_required_samples_for_frame(void* ctx_ptr) {
    if (ctx_ptr == nullptr) return -1;
    FskContext* ctx = static_cast<FskContext*>(ctx_ptr);
    int32_t total_bits = PREAMBLE_BITS + SYNC_WORD_BITS + HAMMING_BITS_TOTAL;
    return total_bits * ctx->symbol_samples;
}

int32_t ultrasound_fsk_encode_frame(
    void* ctx_ptr,
    const uint8_t* frame_logical_bytes,
    float* output,
    int32_t output_len
) {
    if (ctx_ptr == nullptr || frame_logical_bytes == nullptr || output == nullptr) return -1;

    FskContext* ctx = static_cast<FskContext*>(ctx_ptr);
    int32_t required = ultrasound_fsk_required_samples_for_frame(ctx_ptr);
    if (required < 0 || output_len < required) return -1;

    int32_t write_pos = 0;

    // Préambule (32 bits de 0xAAAAAAAA, MSB first).
    for (int i = PREAMBLE_BITS - 1; i >= 0; --i) {
        uint8_t bit = (uint8_t)((PREAMBLE_PATTERN >> i) & 1);
        emit_bit(ctx, bit, output, write_pos);
    }

    // Mot de synchronisation (16 bits, MSB first).
    for (int i = SYNC_WORD_BITS - 1; i >= 0; --i) {
        uint8_t bit = (uint8_t)((SYNC_WORD >> i) & 1);
        emit_bit(ctx, bit, output, write_pos);
    }

    // Données protégées par Hamming(7,4), nibble par nibble.
    for (int32_t byte_idx = 0; byte_idx < LOGICAL_BYTES; ++byte_idx) {
        uint8_t byte_val = frame_logical_bytes[byte_idx];
        uint8_t high_nibble = (uint8_t)((byte_val >> 4) & 0x0F);
        uint8_t low_nibble = (uint8_t)(byte_val & 0x0F);

        uint8_t codeword[7];

        hamming74_encode(high_nibble, codeword);
        for (int b = 0; b < 7; ++b) emit_bit(ctx, codeword[b], output, write_pos);

        hamming74_encode(low_nibble, codeword);
        for (int b = 0; b < 7; ++b) emit_bit(ctx, codeword[b], output, write_pos);
    }

    return write_pos;
}

// ────────────────────────────────────────────────────────────
// DÉCODAGE — Goertzel pour un bit, puis machine à états de trame
// ────────────────────────────────────────────────────────────

static float goertzel_energy(const float* samples, int32_t num_samples, double target_freq, int32_t sample_rate) {
    double k = (double)num_samples * target_freq / sample_rate;
    double omega = 2.0 * PI * k / num_samples;
    double coeff = 2.0 * cos(omega);

    double s_prev2 = 0.0, s_prev1 = 0.0, s_curr = 0.0;
    for (int32_t i = 0; i < num_samples; ++i) {
        s_curr = samples[i] + coeff * s_prev1 - s_prev2;
        s_prev2 = s_prev1;
        s_prev1 = s_curr;
    }
    return (float)(s_prev1 * s_prev1 + s_prev2 * s_prev2 - coeff * s_prev1 * s_prev2);
}

int32_t ultrasound_fsk_decode_bit(void* ctx_ptr, const float* audio_input, int32_t input_len, uint8_t* output_bit) {
    if (ctx_ptr == nullptr || audio_input == nullptr || output_bit == nullptr) return -1;
    FskContext* ctx = static_cast<FskContext*>(ctx_ptr);
    if (input_len < ctx->symbol_samples) return 0;

    float energy0 = goertzel_energy(audio_input, ctx->symbol_samples, ctx->freq_bit0, ctx->sample_rate);
    float energy1 = goertzel_energy(audio_input, ctx->symbol_samples, ctx->freq_bit1, ctx->sample_rate);

    float total = energy0 + energy1;
    if (total < 0.001f) return 0;

    *output_bit = (energy1 > energy0) ? 1 : 0;
    return 1;
}

enum class DecoderState : uint8_t {
    SEARCHING_PREAMBLE,
    SEARCHING_SYNC,
    RECEIVING_DATA,
};

struct FrameDecoder {
    FskContext* fsk_ctx;
    DecoderState state;

    uint32_t preamble_shift_register;
    uint16_t sync_shift_register;
    int32_t sync_bits_seen;

    // Accumulation des blocs de Hamming(7,4).
    uint8_t current_codeword[7];
    int32_t codeword_bit_count;
    int32_t nibbles_received; // 0..LOGICAL_NIBBLES
    uint8_t logical_buffer[LOGICAL_BYTES];
    bool have_high_nibble;
    uint8_t pending_high_nibble;
};

void* ultrasound_frame_decoder_create(void* fsk_ctx_ptr) {
    if (fsk_ctx_ptr == nullptr) return nullptr;
    FrameDecoder* dec = new (std::nothrow) FrameDecoder();
    if (dec == nullptr) return nullptr;

    dec->fsk_ctx = static_cast<FskContext*>(fsk_ctx_ptr);
    dec->state = DecoderState::SEARCHING_PREAMBLE;
    dec->preamble_shift_register = 0;
    dec->sync_shift_register = 0;
    dec->sync_bits_seen = 0;
    dec->codeword_bit_count = 0;
    dec->nibbles_received = 0;
    dec->have_high_nibble = false;
    dec->pending_high_nibble = 0;
    memset(dec->logical_buffer, 0, sizeof(dec->logical_buffer));
    memset(dec->current_codeword, 0, sizeof(dec->current_codeword));
    return dec;
}

void ultrasound_frame_decoder_destroy(void* decoder_ptr) {
    if (decoder_ptr == nullptr) return;
    delete static_cast<FrameDecoder*>(decoder_ptr);
}

void ultrasound_frame_decoder_reset(void* decoder_ptr) {
    if (decoder_ptr == nullptr) return;
    FrameDecoder* dec = static_cast<FrameDecoder*>(decoder_ptr);
    dec->state = DecoderState::SEARCHING_PREAMBLE;
    dec->preamble_shift_register = 0;
    dec->sync_shift_register = 0;
    dec->sync_bits_seen = 0;
    dec->codeword_bit_count = 0;
    dec->nibbles_received = 0;
    dec->have_high_nibble = false;
    dec->pending_high_nibble = 0;
    memset(dec->logical_buffer, 0, sizeof(dec->logical_buffer));
    memset(dec->current_codeword, 0, sizeof(dec->current_codeword));
}

int32_t ultrasound_frame_decoder_feed_bit(
    void* decoder_ptr,
    uint8_t bit,
    uint8_t* output_frame,
    int32_t output_len
) {
    if (decoder_ptr == nullptr || output_frame == nullptr) return -1;
    if (output_len < LOGICAL_BYTES) return -1;
    if (bit > 1) return -1;

    FrameDecoder* dec = static_cast<FrameDecoder*>(decoder_ptr);

    // Le registre de préambule tourne EN PERMANENCE, quel que soit
    // l'état courant — y compris pendant SEARCHING_SYNC et
    // RECEIVING_DATA. Sans ça, un faux verrouillage ponctuel (un
    // motif de bruit qui matche 0xAAAAAAAA par coïncidence à la
    // frontière bruit/signal) peut "consommer" une partie du VRAI
    // préambule ; il ne reste alors plus assez de bits alternants
    // pour reformer une fenêtre de 32 bits propre, et la trame
    // réelle qui suit immédiatement est perdue sans recours. En
    // laissant le registre tourner toujours, dès que 32 bits
    // consécutifs réellement alternants passent — peu importe l'état
    // nominal — la resynchronisation se fait immédiatement.
    dec->preamble_shift_register = (dec->preamble_shift_register << 1) | (uint32_t)bit;

    if (dec->preamble_shift_register == PREAMBLE_PATTERN) {
        dec->state = DecoderState::SEARCHING_SYNC;
        dec->sync_shift_register = 0;
        dec->sync_bits_seen = 0;
        dec->codeword_bit_count = 0;
        dec->nibbles_received = 0;
        dec->have_high_nibble = false;

    }

    if (dec->state == DecoderState::SEARCHING_PREAMBLE) {
        return 0;
    }

    if (dec->state == DecoderState::SEARCHING_SYNC) {
        dec->sync_shift_register = (uint16_t)((dec->sync_shift_register << 1) | bit);
        dec->sync_bits_seen++;

        if (dec->sync_bits_seen >= SYNC_WORD_BITS) {
            if (dec->sync_shift_register == SYNC_WORD) {
                dec->state = DecoderState::RECEIVING_DATA;
                dec->codeword_bit_count = 0;
                dec->nibbles_received = 0;
                dec->have_high_nibble = false;
            } else {
                // Le mot de synchronisation ne correspond pas —
                // repart en recherche de préambule. Le registre de
                // préambule, lui, n'a jamais cessé de tourner : si le
                // vrai préambule se termine plus loin dans ce même
                // flux, il sera détecté dès qu'il apparaît, sans
                // dépendre d'un redémarrage complet à zéro.
                dec->state = DecoderState::SEARCHING_PREAMBLE;
                dec->sync_shift_register = 0;
                dec->sync_bits_seen = 0;
            }
        }
        return 0;
    }

    // RECEIVING_DATA — accumulation d'un mot de Hamming(7,4) à la fois.
    dec->current_codeword[dec->codeword_bit_count] = bit;
    dec->codeword_bit_count++;

    if (dec->codeword_bit_count < 7) {
        return 0;
    }

    dec->codeword_bit_count = 0;
    uint8_t nibble = hamming74_decode(dec->current_codeword);

    if (!dec->have_high_nibble) {
        dec->pending_high_nibble = nibble;
        dec->have_high_nibble = true;
    } else {
        int32_t byte_idx = dec->nibbles_received / 2;
        dec->logical_buffer[byte_idx] = (uint8_t)((dec->pending_high_nibble << 4) | nibble);
        dec->have_high_nibble = false;
    }

    dec->nibbles_received++;

    if (dec->nibbles_received < LOGICAL_NIBBLES) {
        return 0;
    }

    uint16_t received_crc = (uint16_t)(
        (dec->logical_buffer[LOGICAL_BYTES - 2] << 8) |
        dec->logical_buffer[LOGICAL_BYTES - 1]
    );
    uint16_t computed_crc = crc16_ccitt(dec->logical_buffer, LOGICAL_BYTES - 2);

    if (received_crc != computed_crc) {
        dec->state = DecoderState::SEARCHING_PREAMBLE;
        dec->sync_shift_register = 0;
        dec->sync_bits_seen = 0;
        dec->codeword_bit_count = 0;
        dec->nibbles_received = 0;
        dec->have_high_nibble = false;
        return 0;
    }

    memcpy(output_frame, dec->logical_buffer, LOGICAL_BYTES);
    dec->state = DecoderState::SEARCHING_PREAMBLE;
    dec->sync_shift_register = 0;
    dec->sync_bits_seen = 0;
    dec->codeword_bit_count = 0;
    dec->nibbles_received = 0;
    dec->have_high_nibble = false;
    return LOGICAL_BYTES;
}
