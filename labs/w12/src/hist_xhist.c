#include <stdint.h>
#include <stdio.h>
#include "xhist_intrin.h"

#define N 4096
#define NBINS 256
#define SAT_LIMIT 255

static uint32_t input[N];
static uint32_t hist[NBINS];

static void init_input(void)
{
    for (uint32_t i = 0; i < N; i++) {
#if defined(MODE_HOT_BIN_CLUSTERED)
        input[i] = ((i * 5 + 3) & 0x1f);
#elif defined(MODE_OUT_OF_RANGE_HEAVY)
        if ((i & 3) == 0) {
            input[i] = (i * 37 + 13) & 0x3ff;
        } else {
            input[i] = 1024 + ((i * 37 + 13) & 0x3ff);
        }
#elif defined(MODE_ADVERSARIAL_STRIDE)
        input[i] = (i * 16) & 0x3ff;
#else
        input[i] = (i * 37 + 13) & 0x3ff;
#endif
    }
}

static uint32_t checksum(void)
{
    uint32_t s = 0;
    for (uint32_t i = 0; i < NBINS; i++) {
        s = (s * 131) ^ hist[i];
    }
    return s;
}

int main(void)
{
    init_input();

    uint64_t min_val = 0;
    uint64_t max_val = 1024;
    uint64_t shift = 2;

    uint64_t range_cfg = (max_val << 32) | min_val;
    uint64_t bin_cfg = (shift << 16) | min_val;

    for (uint32_t i = 0; i < N; i++) {
        uint64_t x = input[i];

        if (xhrange(x, range_cfg)) {
            uint64_t bin = xhbin(x, bin_cfg);
            hist[bin] = xhsat(hist[bin], SAT_LIMIT);
        }
    }

    printf("mode: xhist\n");
    printf("checksum: 0x%08x\n", checksum());

    return 0;
}
