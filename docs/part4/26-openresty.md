# 26. OpenResty: Lua Inside Nginx

--8<-- "includes/badges/26-openresty.md"

!!! abstract "What you will be able to do after this lesson"
    - Place Lua code in the right nginx **phase** (`init`, `rewrite`, `access`, `content`, filters, `log`).
    - Use the core `ngx.*` API: variables, request args/headers/body, shared dicts, regexes, subrequests.
    - Do network I/O with **cosockets** (`ngx.socket.tcp`, `resty.redis`), light threads and timers.
    - Build a small API gateway: routing, API keys, Redis rate limiting, request ids, aggregation, metrics.

!!! info "Which Lua does OpenResty run?"
    OpenResty bundles **its own LuaJIT fork** (`openresty/luajit2`, Lua 5.1
    semantics plus extensions such as `table.new`/`table.clear`). The tested
    server is **OpenResty 1.31.8.1** built from the release tarball (with PCRE2
    10.49, zlib 1.4 and the system OpenSSL). Its bundled LuaJIT is the
    `LuaJIT-2.1-20261023` snapshot; because the tarball carries no git history,
    `jit.version` reports `LuaJIT 2.1.ROLLING` rather than a commit timestamp.

## The intuition

Nginx processes each request through a fixed sequence of **phases**. OpenResty
lets you hook Lua into each phase, and it runs your Lua **inside nginx's event
loop**: every request is a Lua coroutine, and whenever your code waits for the
network (`sock:receive()`, `ngx.sleep`, a Redis call), the coroutine yields and
the worker serves other requests. Code looks blocking but is not.

```text
init_by_lua          master, once, before forking workers
init_worker_by_lua   each worker, once
  ┌ per request ───────────────────────────────────────────────────────┐
  │ set_by_lua → rewrite_by_lua → access_by_lua → content_by_lua       │
  │            (or proxy_pass)    → header_filter_by_lua → body_filter │
  │            → log_by_lua (after the response is sent)               │
  └────────────────────────────────────────────────────────────────────┘
```

!!! note "For C++/Rust developers"
    This is cooperative async I/O, like a single-threaded `tokio` runtime or
    Boost.Asio with coroutines, except the `.await`s are invisible: any cosocket
    call is a suspension point. The same rule applies: **never block the event
    loop**. `io.open`, `os.execute`, LuaSocket or a blocking database driver
    inside a request handler freezes every connection on that worker. Use
    cosocket-based libraries (`resty.*`) instead.

## How the examples are tested

One OpenResty instance hosts the whole lesson: a demo server, a gateway and two
fake backends, configured by `conf/*.conf`. Each `*.test.sh` driver starts it in a
throw-away prefix with the helpers below, talks to it with `curl`, and stops it.
Any `[error]` line in nginx's `error.log` is printed, so it fails the test.

```bash title="examples/26-openresty/openresty.sh"
--8<-- "examples/26-openresty/openresty.sh"
```

```nginx title="examples/26-openresty/conf/nginx.conf"
--8<-- "examples/26-openresty/conf/nginx.conf"
```

## Phases

```nginx title="examples/26-openresty/conf/phases.conf"
--8<-- "examples/26-openresty/conf/phases.conf"
```

```bash title="examples/26-openresty/phases.test.sh"
--8<-- "examples/26-openresty/phases.test.sh"
```

```text title="Output (OpenResty 1.31.8.1)"
--8<-- "examples/26-openresty/phases.expected"
```

Look closely at "phases so far": `header_filter` ran **in the middle of the
content handler**, because the first `ngx.say` sends the response headers, which
runs the header filter right then. The second `ngx.say` already sees it. That is
why status and headers must be set before the first byte of output.

## The `ngx.*` API

```nginx title="examples/26-openresty/conf/apis.conf"
--8<-- "examples/26-openresty/conf/apis.conf"
```

```lua title="examples/26-openresty/lua/apis.lua"
--8<-- "examples/26-openresty/lua/apis.lua"
```

```bash title="examples/26-openresty/apis.test.sh"
--8<-- "examples/26-openresty/apis.test.sh"
```

```text title="Output"
--8<-- "examples/26-openresty/apis.expected"
```

- `ngx.shared.DICT` is shared memory across **all workers** with atomic `incr`
  and per-key TTLs. Plain Lua tables are per worker, and module-level state is
  shared by all requests on that worker, so never keep request data there.
- Always pass `"jo"` to `ngx.re.*`: PCRE JIT plus a compiled-pattern cache.
- `ngx.location.capture_multi` runs subrequests in parallel without the network.

## Cosockets, light threads and timers

```lua title="examples/26-openresty/lua/http_get.lua"
--8<-- "examples/26-openresty/lua/http_get.lua"
```

```lua title="examples/26-openresty/lua/cosockets.lua"
--8<-- "examples/26-openresty/lua/cosockets.lua"
```

```bash title="examples/26-openresty/cosockets.test.sh"
--8<-- "examples/26-openresty/cosockets.test.sh"
```

```text title="Output"
--8<-- "examples/26-openresty/cosockets.expected"
```

- `set_keepalive` returns the connection to a **per-worker pool**; the second
  request reports `reused times: 1` because it got the pooled connection.
- `ngx.thread.spawn` runs functions concurrently *within* one request: two
  300 ms backend calls finish in about 300 ms, not 600.
- Cosockets are not available in `init_by_lua`, `set_by_lua`, header/body
  filters or `log_by_lua`; do I/O in `rewrite`, `access`, `content` or timers.

## A small API gateway

```nginx title="examples/26-openresty/conf/gateway.conf"
--8<-- "examples/26-openresty/conf/gateway.conf"
```

```lua title="examples/26-openresty/lua/gateway.lua"
--8<-- "examples/26-openresty/lua/gateway.lua"
```

```lua title="examples/26-openresty/lua/backends.lua"
--8<-- "examples/26-openresty/lua/backends.lua"
```

```bash title="examples/26-openresty/gateway.test.sh"
--8<-- "examples/26-openresty/gateway.test.sh"
```

```text title="Output"
--8<-- "examples/26-openresty/gateway.expected"
```

The gateway reuses Lesson 25's `ratelimit_fixed.lua` unchanged: it reads the file
in `init_by_lua` (blocking I/O is fine before the workers start), computes its
SHA1, and calls `EVALSHA` over a pooled cosocket, falling back to `EVAL` on
`NOSCRIPT`. If Redis is down it **fails open** and counts the error, a policy
decision you should make explicitly. OpenResty also ships `resty.limit.req` and
`resty.limit.count` for shared-dict (single-node) limits.

## Hands-on exercises

```nginx title="examples/26-openresty/conf/exercises.conf"
--8<-- "examples/26-openresty/conf/exercises.conf"
```

??? example "Exercise 1: a validated JSON endpoint"
    Accept `POST` JSON with `name` (non-empty string) and `age` (integer 0-150);
    answer 201, 400 with a list of problems, 415 for the wrong content type, 405 for other methods.

    ??? success "Solution"
        ```lua
        --8<-- "examples/26-openresty/lua/ex1_validate.lua"
        ```

??? example "Exercise 2: per-path hit counters"
    Count hits per URI in a shared dict and list the top three on `/ex2/top`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/26-openresty/lua/ex2_hits.lua"
        ```

??? example "Exercise 3: cache-aside with Redis"
    Cache an expensive computation in Redis for 30 s and report `X-Cache: HIT/MISS`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/26-openresty/lua/ex3_cache.lua"
        ```

??? example "Exercise 4: HMAC-signed requests"
    Verify an `X-Signature` HMAC-SHA1 over method, URI and timestamp, rejecting
    old timestamps to prevent replay.

    ??? success "Solution"
        ```lua
        --8<-- "examples/26-openresty/lua/ex4_hmac.lua"
        ```

??? success "All four exercises, tested"
    ```bash
    --8<-- "examples/26-openresty/exercises.test.sh"
    ```
    ```text
    --8<-- "examples/26-openresty/exercises.expected"
    ```

## Quiz

??? question "Q1. In which phase do API-key checks belong, and why not in `content_by_lua`?"
    `access_by_lua`: it runs before the content phase, so it also protects
    `proxy_pass` locations, and it can end the request early with `ngx.exit(401)`.

??? question "Q2. Why must you not call `io.open` or LuaSocket in a request handler?"
    They block the worker's event loop, stalling every request on that worker.
    Cosockets (and `resty.*` libraries built on them) yield instead.

??? question "Q3. You set `ngx.header['X-A']` after `ngx.say(...)`. What happens?"
    The headers were already sent by the first output; the change is ignored
    (and logged as an error). Set status and headers first.

??? question "Q4. Where can state shared by all workers live?"
    In `lua_shared_dict` zones (`ngx.shared.NAME`), or outside nginx (Redis).
    Lua tables and module variables are per worker.

??? question "Q5. Which Lua runs inside OpenResty?"
    OpenResty's LuaJIT 2.1 fork (Lua 5.1 semantics), here the 2.1-20261023 bundle.
