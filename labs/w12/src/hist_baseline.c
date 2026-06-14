#include <stdint.h>
#include <stdio.h>
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
        if ((i & 3) == 0) { // 1/4 is in-range
            input[i] = (i * 37 + 13) & 0x3ff;
        } else { // other 3/4 is out-of-range
            input[i] = 1024 + ((i * 37 + 13) & 0x3ff);
        }
#elif defined(MODE_ADVERSARIAL_STRIDE)
        // i*16, >> 2 => stride of 4
        // cache line size = 64 = 2 integers
        // => miss each access
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

    uint32_t min_val = 0;
    uint32_t max_val = 1024;
    uint32_t shift = 2;

    for (uint32_t i = 0; i < N; i++) {
        uint32_t x = input[i];

        if (x >= min_val && x < max_val) {
            uint32_t bin = (x - min_val) >> shift;

            if (hist[bin] < SAT_LIMIT) {
                hist[bin]++;
            }
        }
    }

    printf("mode: baseline\n");
    printf("checksum: 0x%08x\n", checksum());

    return 0;
}
