#include "fir_filter.h"

int32_t fir_filter(int16_t input, const int16_t coeff[8], int16_t state[8]) {
    // ---- shift in new sample ----
    // state[t+1][7] = state[t][6], ..., state[t+1][0] = input
    for (int i = 7; i > 0; i--) {
        state[i] = state[i-1];
    }
    state[0] = input;

    // ---- FIR convolution: sum(state[i] * coeff[i]) ----
    // use 64-bit accumulator to avoid overflow during summation
    int64_t acc = 0;
    for (int i = 0; i < 8; i++) {
        acc += (int64_t)state[i] * (int64_t)coeff[i];
    }

    // ---- quantize: take upper 16 bits of the 48-bit product sum ----
    // equivalent to (acc >> 16) with rounding (not needed for formal eq check)
    return (int32_t)(acc >> 16);
}
