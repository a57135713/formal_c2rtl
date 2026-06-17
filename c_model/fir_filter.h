#ifndef FIR_FILTER_H
#define FIR_FILTER_H

#include <stdint.h>

// 8-tap FIR filter
//   input  : 16-bit signed sample
//   coeff  : 8 fixed 16-bit signed coefficients (read-only)
//   state  : 8-element delay line (updated each call with new input)
//   returns: 32-bit signed — upper 16 bits of the accumulated sum
int32_t fir_filter(int16_t input, const int16_t coeff[8], int16_t state[8]);

#endif
