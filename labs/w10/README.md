# Week 10 Lab. Debugging a Broken Snooping Invalidation Interface

## 1. Introduction

This lab presents a simple small shared-memory system with two private caches and a snooping invalidation interface. The top-level integration originally contained three seeded bugs that prevented proper invalidation propagation between caches. This lab demonstrates how a small system prototype debugging works and system integration challenges.

## 2. Workflow

The exercise focuses on fixing those integration bugs in `rtl/tiny_system_todo.sv` while keeping the cache implementation and testbench unchanged.

``` bash
$ ./run.sh # compile and run
```

## 3. What Is Broken?

Two private caches and a shared memory are connected through a tiny snooping invalidation interface. Each cache is correct by itself. The top-level integration contains three seeded bugs:

1. Core 1 write invalidation toward Core 0 is suppressed.
2. Core 1 invalidation address toward Core 0 is truncated.
3. Core 0 invalidation address toward Core 1 is truncated.

## 4. Correct Interface Contract

- When Core 0 writes address A, Core 1 must receive an invalidate for address A.
- When Core 1 writes address A, Core 0 must receive an invalidate for address A.
- The full address must be used for snoop comparison.

## 5. Conclusion

I corrected the snoop signal assignments so valid flags and full addresses are forwarded between the caches, resolving suppressed invalidations and address truncation. After the fixes the simulation no longer reports stale reads and caches correctly invalidate remote-written lines. Key takeaways: small integration mistakes such as signal suppression or bit-width truncation can break coherence, and clear debug outputs greatly accelerate root-cause analysis. Only `rtl/tiny_system_todo.sv` was modified; the cache module and testbench remain intact.
