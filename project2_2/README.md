# Project 2-2. Gem5 Histogram Worklaod Profiling

## 1. Histogram Workload Optimization

``` C
for (int i = 0; i < N; i++) {
    uint8_t v = input_data[i];

    if (v < 16) bins[0]++;
    else if (v < 32) bins[1]++;
    else if (v < 48) bins[2]++;
    else if (v < 64) bins[3]++;
    else if (v < 80) bins[4]++;
    else if (v < 96) bins[5]++;
    else if (v < 112) bins[6]++;
    else if (v < 128) bins[7]++;
    else if (v < 144) bins[8]++;
    else if (v < 160) bins[9]++;
    else if (v < 176) bins[10]++;
    else if (v < 192) bins[11]++;
    else if (v < 208) bins[12]++;
    else if (v < 224) bins[13]++;
    else if (v < 240) bins[14]++;
    else bins[15]++;
}
```

``` C
int local_bins[BINS] = {0};

for (int i = 0; i < N; i++) {
    uint8_t v = input_data[i];
    local_bins[v >> 4]++;
}

for (int i = 0; i < BINS; i++) bins[i] += local_bins[i];
```

## 2. Performance Characterization

The following table presents the simulation results comparing the baseline and optimized implementations:

| Metric | Baseline Value | Optimized Value | Improvement |
|--------|----------------|-----------------|-------------|
| simInsts | 214,819 | 176,572 | 17.80% |
| system.cpu.numCycles | 289,185 | 233,316 | 19.39% |
| system.cpu.cpi | 1.346180 | 1.321365 | 1.84% |
| system.cpu.ipc | 0.742843 | 0.756793 | -1.88% |
| system.cpu.commitStats0.cpi | 1.346180 | 1.321365 | 1.84% |
| system.cpu.commitStats0.ipc | 0.742843 | 0.756793 | -1.88% |

- **Instruction Count Reduction**: The optimized version executes significantly fewer instructions (17.80% fewer simulated instructions), demonstrating the effectiveness of the bit-shift approach in eliminating the need for 15 conditional branches per iteration.

- **Cycle Count Reduction**: The optimized version completes in 19.39% fewer cycles, indicating better overall pipeline efficiency and reduced branch misprediction penalties.

- **Memory Behavior**: The optimized version benefits from improved cache locality. The `local_bins[]` array is stack-allocated within the loop scope, allowing the compiler to apply aggressive optimizations (such as -O2) and increase instruction spatial locality.

- **Branch Elimination**: The baseline program is inherently branch-heavy, requiring the CPU to evaluate up to 15 conditional branches per iteration to determine which bin to increment. The optimized version eliminates this branching through the simple bit-shift operation (`v >> 4`).

## 3. Conclusion

This project successfully demonstrates the power of algorithmic optimization in reducing both instruction count and execution time. Key insights include:

1. **Branch Prediction vs. Algorithmic Design**: While branch prediction can help with regular patterns, the baseline version's random-access nature makes branch prediction less effective. The optimized version achieves better performance by eliminating branching entirely rather than relying on prediction.

2. **Cache Configuration Impact**: For the baseline implementation, branch handling and prediction are critical performance factors. However, for the optimized version, the cache configuration becomes the dominant factor since the branching complexity is eliminated and data movement efficiency matters more than computation.

3. **Compiler Optimization**: Using a local array with limited scope allows the compiler to apply aggressive optimizations (-O2), resulting in better instruction scheduling and reduced memory access latency.

4. **Practical Performance Gains**: The 19.39% reduction in cycle count demonstrates that simple, elegant algorithmic improvements can yield substantial performance benefits without requiring complex hardware enhancements or branch prediction schemes.
