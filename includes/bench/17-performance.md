!!! info "Measured on 2026-11-17 by `tests/bench.sh`"
    CPU: Intel(R) Xeon(R) Processor, 8 logical CPUs, Linux 6.12.113+.
    Lua 5.5.1, Lua 5.4.9 (both `-O2`), LuaJIT 2.1.1794386141.
    CPU time in milliseconds, best of 5 runs; lower is better. Shared cloud
    machine, so treat differences under ~10% as noise. Re-run on your machine.

| Benchmark | Variant | Lua 5.5 | Lua 5.4 | LuaJIT 2.1 | LuaJIT `-joff` |
|---|---|---:|---:|---:|---:|
| locals vs globals | global math.floor | 22.83 | 23.61 | 1.00 | 9.19 |
| locals vs globals | local floor | 16.04 | 17.44 | 1.00 | 6.11 |
| locals vs globals | upvalue floor | 16.25 | 15.94 | 1.00 | 6.38 |
| string building | s = s .. x in a loop | 33.31 | 35.13 | 43.97 | 61.82 |
| string building | table + table.concat | 3.59 | 3.53 | 1.43 | 2.53 |
| string building | buffer with counter | 2.50 | 2.47 | 0.38 | 0.51 |
| array append | table.insert(t, v) | 32.54 | 30.76 | 3.85 | 57.66 |
| array append | t[#t + 1] = v | 14.91 | 12.63 | 3.73 | 52.48 |
| array append | t[i] = v | 9.28 | 7.67 | 3.06 | 6.33 |
| array append | table.create(N) + t[i] = v | 4.69 | n/a | n/a | n/a |
| array iteration | for i = 1, #t | 5.48 | 6.28 | 0.52 | 5.26 |
| array iteration | ipairs | 14.22 | 14.53 | 0.60 | 6.03 |
| array iteration | pairs | 14.68 | 15.79 | 2.08 | 2.42 |
| vector maths | new table per add | 40.74 | 47.85 | 0.25 | 29.77 |
| vector maths | multiple returns | 10.16 | 10.62 | 0.25 | 5.19 |
| closures in loops | new closure each iteration | 57.66 | 56.76 | 10.19 | 32.72 |
| closures in loops | closure hoisted out of the loop | 50.97 | 54.19 | 4.22 | 27.56 |
| ex1 gain loop | slow: globals, table.insert, repeated field lookups | 36.13 | 38.26 | 2.27 | 39.01 |
| ex1 gain loop | fast: hoisted locals, direct index | 16.67 | 15.57 | 1.81 | 8.90 |
| ex2 csv report | slow: csv = csv .. line | 8.78 | 8.69 | 7.98 | 11.08 |
| ex2 csv report | fast: buffer + table.concat | 1.76 | 1.90 | 0.48 | 0.80 |
| ex3 fibonacci(27) | naive recursion | 8.88 | 8.27 | 1.02 | 7.16 |
| ex3 fibonacci(27) | memoized | < 0.01 | < 0.01 | < 0.01 | < 0.01 |
| ex4 byte checksum | s:sub(i, i):byte() | 59.56 | 71.99 | 0.53 | 32.66 |
| ex4 byte checksum | s:byte(i) | 22.67 | 24.79 | 0.52 | 10.97 |
| ex4 byte checksum | s:byte(i, i + 7), 8 at a time | 5.97 | 6.33 | 0.52 | 2.99 |
