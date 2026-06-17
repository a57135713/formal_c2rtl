# FIR Filter — C Reference Model

8-tap FIR filter, 16-bit signed input/coefficients, 32-bit quantized output.

## Function

```c
int32_t fir_filter(int16_t input, const int16_t coeff[8], int16_t state[8]);
```

- `input`: 16-bit signed sample
- `coeff`: 8 fixed 16-bit signed coefficients
- `state`: 8-element delay line (updated in-place each call)
- Returns: 32-bit signed (upper 16 bits of the accumulated 48-bit sum)
