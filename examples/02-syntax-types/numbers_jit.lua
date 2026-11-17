-- targets: jit
-- numbers_jit.lua: LuaJIT has only doubles (plus FFI 64-bit boxed integers)
print(3, 3.0, 10 / 2, 2^3, 7 % 3, -7 % 3)
print(math.floor(7 / 2), math.floor(-7 / 2))  -- no '//' operator in 5.1
print(2^53 == 2^53 + 1)                       -- above 2^53 integers are inexact
print(1 / 0, -1 / 0)
print("10" + 1, 10 .. 20)
print(1LL, type(1LL), 2LL^62)                 -- FFI int64_t literal (LuaJIT only)
