!!! info "Measured on 2026-11-17 by `tests/bench.sh`"
    CPU: Intel(R) Xeon(R) Processor, 8 logical CPUs, Linux 6.12.113+.
    Lua 5.5.1, Lua 5.4.9 (both `-O2`), LuaJIT 2.1.1794386141.
    CPU time in milliseconds, best of 5 runs; lower is better. Shared cloud
    machine, so treat differences under ~10% as noise. Re-run on your machine.

| Benchmark | Variant | LuaJIT 2.1 | LuaJIT `-joff` |
|---|---|---:|---:|
| sum 1M doubles | Lua table | 3.30 | 10.99 |
| sum 1M doubles | FFI double[N] | 2.92 | 47.74 |
| RGB to grey, 640x480 | Lua table of bytes | 5.01 | 17.04 |
| RGB to grey, 640x480 | FFI uint8_t buffers | 1.46 | 54.13 |
| array of 200k points | table of tables | 8.64 | 13.79 |
| array of 200k points | FFI pt_t[M] | 0.42 | 38.21 |
| 1M square roots | math.sqrt | 4.50 | 5.08 |
| 1M square roots | ffi.C.sqrt | 2.00 | 40.21 |
