# 25. Redis Scripting: EVAL, Atomic Scripts and Functions

--8<-- "includes/badges/25-redis.md"

!!! abstract "What you will be able to do after this lesson"
    - Run Lua inside Redis with `EVAL`/`EVALSHA`, passing keys in `KEYS` and values in `ARGV`.
    - Predict how Lua values become Redis replies and back.
    - Build atomic rate limiters (fixed window and token bucket) and prove the atomicity.
    - Handle errors (`redis.call` vs `redis.pcall`, error replies) and runaway scripts.
    - Package code as a Redis Functions library (`FUNCTION LOAD`, `FCALL`, `FCALL_RO`).

!!! info "Which Lua does Redis run?"
    Redis embeds **PUC Lua 5.1** (its own patched copy in `deps/lua`), not LuaJIT
    and not 5.4. The tested server, **Redis 8.10.3** built from source, answers
    `EVAL "return _VERSION" 0` with `Lua 5.1`. The sandbox preloads `cjson`,
    `cmsgpack`, `bit` and `struct`; `os` contains only `os.clock`; there is no
    `io`, no `require`/`loadfile`, and globals cannot be created.

## The intuition

Redis runs commands one at a time on a single thread. A Lua script is executed
**as one command**: while it runs, no other client's command can interleave.
That turns "read, decide, write" sequences, which are race conditions when done
from a client, into atomic operations, and saves round trips too.

```text
client A: GET counter -> 4 ...................... SET counter 5
client B:        GET counter -> 4 ... SET counter 5          (lost update)

EVAL "local n = redis.call('INCR', KEYS[1]) ..."  (nothing can run in between)
```

!!! note "For C++/Rust developers"
    A script is like a stored procedure that holds a global lock, a short
    critical section executed inside the server. Keep it short: a slow script
    blocks *every* client, just as a long critical section stalls every thread
    waiting on the mutex.

## EVAL, EVALSHA and `redis-cli --eval`

```lua title="examples/25-redis/hello.lua"
--8<-- "examples/25-redis/hello.lua"
```

```bash title="examples/25-redis/basics.test.sh"
--8<-- "examples/25-redis/basics.test.sh"
```

```text title="Output (Redis 8.10.3)"
--8<-- "examples/25-redis/basics.expected"
```

- `EVAL script numkeys key... arg...`; `redis-cli --eval file key... , arg...` builds that for you.
- The server caches scripts by **SHA1 of their text**. Clients send `EVALSHA`
  and fall back to `EVAL` on a `NOSCRIPT` error, as the gateway in Lesson 26 does.
  The script cache is not persisted: after a restart or `SCRIPT FLUSH` it is empty.
- Put every key a script touches in `KEYS`. Redis Cluster uses them to route the
  call and to refuse scripts whose keys live on different shards; `{user42}`
  hash tags keep related keys on the same shard.

## Lua values ↔ Redis replies

```lua title="examples/25-redis/conversions.lua"
--8<-- "examples/25-redis/conversions.lua"
```

```bash title="examples/25-redis/conversions.test.sh"
--8<-- "examples/25-redis/conversions.test.sh"
```

```text title="Output"
--8<-- "examples/25-redis/conversions.expected"
```

The traps: numbers are **truncated to integers** (`3.99` → `3`), so return floats
as strings; `false` becomes nil but `true` becomes `1`; arrays stop at the first
`nil`; tables with string keys turn into empty arrays. In the other direction a
missing key (`GET` of nothing) arrives as `false`, not `nil`.

## An atomic rate limiter

```lua title="examples/25-redis/ratelimit_fixed.lua"
--8<-- "examples/25-redis/ratelimit_fixed.lua"
```

```lua title="examples/25-redis/ratelimit_bucket.lua"
--8<-- "examples/25-redis/ratelimit_bucket.lua"
```

```bash title="examples/25-redis/ratelimit.test.sh"
--8<-- "examples/25-redis/ratelimit.test.sh"
```

```text title="Output"
--8<-- "examples/25-redis/ratelimit.expected"
```

The concurrency test is the proof: 200 clients hit the same key at once and
exactly 50 get through, every run. The counter reaches 200 because rejected
requests are still counted (a design choice: it punishes hammering).

## Errors, the sandbox, and runaway scripts

```lua title="examples/25-redis/errors.lua"
--8<-- "examples/25-redis/errors.lua"
```

```bash title="examples/25-redis/errors.test.sh"
--8<-- "examples/25-redis/errors.test.sh"
```

```text title="Output"
--8<-- "examples/25-redis/errors.expected"
```

- `redis.call` turns a command error into a Lua error that aborts the script;
  `redis.pcall` returns it as `{ err = "..." }`.
- **No rollback:** writes made before the error stay. Validate first, write last.
- `redis.error_reply("CODE message")`/`error({err = ...})` produce proper error
  replies; `redis.status_reply` produces `+OK`-style replies.
- After `busy-reply-threshold` ms (default 5000), other clients get `BUSY`
  and may `SCRIPT KILL` a script that has **not written anything yet**. A script
  that already wrote can only be stopped by `SHUTDOWN NOSAVE`.

## Redis Functions (Redis 7+)

`EVAL` scripts are anonymous and live only in a cache. **Functions** are named,
loaded once, persisted in RDB/AOF and replicated, and grouped in libraries:

```lua title="examples/25-redis/ratelimit_lib.lua"
--8<-- "examples/25-redis/ratelimit_lib.lua"
```

```bash title="examples/25-redis/functions.test.sh"
--8<-- "examples/25-redis/functions.test.sh"
```

```text title="Output"
--8<-- "examples/25-redis/functions.expected"
```

The `no-writes` flag is what allows `FCALL_RO` (and running on read-only
replicas). Use Functions for logic that is part of your data model; use `EVAL`
for ad-hoc scripts shipped with an application.

!!! warning "Version differences that bite"
    - Redis ≥ 7: the global table is **read-only** (`counter = 1` fails), and
      Functions exist.
    - Redis ≥ 5 replicates scripts by their *effects* (the write commands they
      ran), so `TIME` and other non-deterministic commands may precede writes.
      Older servers replicated the script text and forbade that; old guides call
      `redis.replicate_commands()`, which Redis 7 turned into a no-op.
    - Lua 5.1 everywhere: no integer subtype, no `goto`, no `//`. Numbers in
      `ARGV` are strings; convert with `tonumber`.

## Hands-on exercises

??? example "Exercise 1: compare-and-set"
    Set a key to a new value only if its current value equals the expected one
    (empty expected value = "must not exist").

    ??? success "Solution"
        ```lua
        --8<-- "examples/25-redis/ex1_cas.lua"
        ```
        ```bash
        --8<-- "examples/25-redis/ex1_cas.test.sh"
        ```
        ```text
        --8<-- "examples/25-redis/ex1_cas.expected"
        ```

??? example "Exercise 2: a sliding-window log limiter"
    Use a sorted set of request timestamps so the window slides instead of
    resetting, and return how long to wait when the limit is hit.

    ??? success "Solution"
        ```lua
        --8<-- "examples/25-redis/ex2_sliding_log.lua"
        ```
        ```bash
        --8<-- "examples/25-redis/ex2_sliding_log.test.sh"
        ```
        ```text
        --8<-- "examples/25-redis/ex2_sliding_log.expected"
        ```

??? example "Exercise 3: atomic JSON updates with cjson"
    Increment a counter inside a JSON document stored in a string key, atomically.

    ??? success "Solution"
        ```lua
        --8<-- "examples/25-redis/ex3_json.lua"
        ```
        ```bash
        --8<-- "examples/25-redis/ex3_json.test.sh"
        ```
        ```text
        --8<-- "examples/25-redis/ex3_json.expected"
        ```

??? example "Exercise 4: an inventory Functions library"
    Write `inv_reserve` (fails with `OUT_OF_STOCK` when there is not enough) and a
    read-only `inv_available` that works with `FCALL_RO`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/25-redis/ex4_inventory_lib.lua"
        ```
        ```bash
        --8<-- "examples/25-redis/ex4_inventory_lib.test.sh"
        ```
        ```text
        --8<-- "examples/25-redis/ex4_inventory_lib.expected"
        ```

## Quiz

??? question "Q1. Why must key names go in `KEYS` rather than `ARGV`?"
    So Redis (especially Cluster) knows which keys the script touches: it routes
    the call to the right shard and rejects cross-slot scripts. ACL key permissions
    are checked against them too.

??? question "Q2. A script returns `2.75`. What does the client receive?"
    The integer `2`: Lua numbers are truncated. Return `tostring(2.75)` instead.

??? question "Q3. A script does `SET a 1`, then a `redis.call` that errors. Is `a` set?"
    Yes. Scripts are atomic (nothing interleaves) but not transactional: there is no rollback.

??? question "Q4. What does the `no-writes` flag on a function enable?"
    Calling it with `FCALL_RO` and on read-only replicas; Redis rejects writes from it.

??? question "Q5. Which Lua version does Redis embed, and which JSON library is available?"
    Lua 5.1 (PUC), with `cjson` (plus `cmsgpack`, `bit`, `struct`) preloaded.
