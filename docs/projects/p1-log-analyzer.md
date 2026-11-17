# Project 1. A Command-Line Log Analyzer

--8<-- "includes/badges/p1-logan.md"

!!! abstract "What you will build"
    `logan`, a command-line tool that reads nginx/Apache **combined** access logs
    and **application** logs, and reports status classes, top paths and clients,
    error counts and a per-minute histogram, as text or JSON. It has a real
    argument parser, a Lua-pattern parser, a test suite in **busted**, a
    **LuaRocks** rockspec that installs a `logan` command, and it is lint-clean
    under **luacheck**. The same code runs unchanged on **Lua 5.5, Lua 5.4 and
    LuaJIT**.

    Uses: [patterns (7)](../part1/07-patterns.md), [closures (9)](../part1/09-closures.md),
    [modules (12)](../part2/12-modules.md), [error handling (13)](../part2/13-errors.md),
    [tooling (28)](../part4/28-tooling.md). Source: `projects/p1-logan/`.

## Design first

A log analyzer is a pipeline with three stages that know nothing about each other:

| Stage | Module | Input → output | Why separate |
|---|---|---|---|
| Parse | `logan.parse` | one line → a record table, or `nil, reason` | the only place that knows log formats |
| Aggregate | `logan.report` | records → counters; counters → text / JSON | the only place that knows the report |
| Drive | `logan` (`init.lua`) + `logan.args` | argv, files → exit status | the only place that touches files and streams |

Two decisions shape the code:

- **Failure is a value, not an exception.** `parse.line` returns `nil, "unrecognised line"`
  and `args.parse` returns `nil, message`, because bad input is *expected* in
  logs and on command lines (Lesson 13). Only programmer errors raise.
- **`main` takes its streams as arguments**: `logan.main(argv, stdout, stderr, stdin)`
  returns an exit status instead of calling `os.exit`. The `bin/logan` script is
  two lines; everything else can be tested without spawning a process.

!!! note "For C++/Rust developers"
    Think of `logan.main` as `int run(std::span<std::string>, std::ostream&, ...)`
    or a Rust `fn run(args, out: &mut impl Write) -> ExitCode`: the binary is a thin
    shell around a testable library. Lua patterns are not regular expressions
    (no alternation `|`, no `{n,m}`), so each format gets one anchored pattern and
    "try the next format" happens in code. Records are plain tables, the Lua
    equivalent of a struct with optional fields (`ms` is `nil` when a line has no duration).

## Step 1: one pattern, one line

Start in the REPL-sized world: match one access-log line and look at the captures.

```lua title="projects/p1-logan/steps/01_match.lua"
--8<-- "projects/p1-logan/steps/01_match.lua"
```

```text title="Output (identical on Lua 5.5, 5.4, LuaJIT)"
--8<-- "projects/p1-logan/steps/01_match.expected"
```

`%[([^%]]+)%]` reads "a literal `[`, capture everything that is not `]`, a literal
`]`". Captures are always **strings**: `tonumber` is your job.

## Step 2: the parser module

```lua title="projects/p1-logan/src/logan/parse.lua"
--8<-- "projects/p1-logan/src/logan/parse.lua"
```

```lua title="projects/p1-logan/steps/02_parse.lua"
--8<-- "projects/p1-logan/steps/02_parse.lua"
```

```text title="Output"
--8<-- "projects/p1-logan/steps/02_parse.expected"
```

Note `path:match("^[^?]*")` dropping the query string (so `/api/streams/42?token=abc`
counts as `/api/streams/42`), and `tonumber(bytes) or 0` turning nginx's `-` into 0.
The sorted-keys loop in the step exists because `pairs` order is unspecified and
**differs between Lua 5.4 and LuaJIT**; anything that prints a table must sort.

## Step 3: aggregation and the text report

```lua title="projects/p1-logan/src/logan/report.lua"
--8<-- "projects/p1-logan/src/logan/report.lua"
```

```lua title="projects/p1-logan/steps/03_report.lua"
--8<-- "projects/p1-logan/steps/03_report.lua"
```

```text title="Output"
--8<-- "projects/p1-logan/steps/03_report.expected"
```

Things worth copying from `report.lua`:

- `report.top` breaks count ties **by key**, so output is deterministic.
- `math.floor(c * 30 / peak + 0.5)` scales the bars. In 5.4/5.5 `math.floor`
  returns an integer, in LuaJIT a float with an integral value; `string.rep` and
  `%d` accept both, so the output is identical.
- `math.floor(rec.status / 100) .. "xx"` builds `"4xx"`. In Lua 5.4 you could write
  `rec.status // 100`, but `//` is a **syntax error** in LuaJIT, and this project
  must load everywhere.
- The JSON encoder is 25 lines because the report needs only strings, integers,
  arrays and objects. One limitation shows in the JSON output below: an **empty
  table** cannot say whether it is an array or an object, so it prints `[]`
  (real libraries such as lua-cjson give you a sentinel for this).

## Step 4: argument parsing

A declarative spec (a list of option tables) drives both parsing and `--help`.

```lua title="projects/p1-logan/src/logan/args.lua"
--8<-- "projects/p1-logan/src/logan/args.lua"
```

```lua title="projects/p1-logan/steps/04_args.lua"
--8<-- "projects/p1-logan/steps/04_args.lua"
```

```text title="Output"
--8<-- "projects/p1-logan/steps/04_args.expected"
```

## Step 5: wiring it up

```lua title="projects/p1-logan/src/logan/init.lua"
--8<-- "projects/p1-logan/src/logan/init.lua"
```

```lua title="projects/p1-logan/bin/logan"
--8<-- "projects/p1-logan/bin/logan"
```

The test drives the real command on each interpreter (`$LUA` is set by the test
runner to Lua 5.5, 5.4 and LuaJIT in turn; all three must produce this output):

```bash title="projects/p1-logan/cli.test.sh"
--8<-- "projects/p1-logan/cli.test.sh"
```

```text title="Output"
--8<-- "projects/p1-logan/cli.expected"
```

The one line that *should* differ, `--version`, has a per-interpreter expected file:

=== "Lua 5.5"
    ```text
    --8<-- "projects/p1-logan/version.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "projects/p1-logan/version.5.4.expected"
    ```
=== "LuaJIT"
    ```text
    --8<-- "projects/p1-logan/version.jit.expected"
    ```

## Step 6: tests with busted

```lua title="projects/p1-logan/.busted"
--8<-- "projects/p1-logan/.busted"
```

```lua title="projects/p1-logan/spec/args_spec.lua"
--8<-- "projects/p1-logan/spec/args_spec.lua"
```

??? info "The other specs (parse, report, cli)"
    ```lua title="projects/p1-logan/spec/parse_spec.lua"
    --8<-- "projects/p1-logan/spec/parse_spec.lua"
    ```
    ```lua title="projects/p1-logan/spec/report_spec.lua"
    --8<-- "projects/p1-logan/spec/report_spec.lua"
    ```
    ```lua title="projects/p1-logan/spec/cli_spec.lua"
    --8<-- "projects/p1-logan/spec/cli_spec.lua"
    ```

`cli_spec.lua` passes **fake streams** (a table with a `write` method) and a fake
stdin (a table with `lines`): duck typing makes the I/O boundary trivially mockable.
busted runs once per interpreter (`busted` on 5.4, `busted5.5`, `busted-jit`):

```bash title="projects/p1-logan/busted.test.sh"
--8<-- "projects/p1-logan/busted.test.sh"
```

```text title="Output (the same TAP on all three)"
--8<-- "projects/p1-logan/busted.expected"
```

## Step 7: a LuaRocks package

```lua title="projects/p1-logan/logan-1.0.0-1.rockspec"
--8<-- "projects/p1-logan/logan-1.0.0-1.rockspec"
```

`install.bin` makes LuaRocks write a **wrapper script** in the tree's `bin/` that
sets `package.path` and runs `bin/logan` with the right interpreter. The test
builds the rock into a throw-away tree for each interpreter and runs the
installed command:

```bash title="projects/p1-logan/rock.test.sh"
--8<-- "projects/p1-logan/rock.test.sh"
```

```text title="Output (the same for 5.5, 5.4 and LuaJIT)"
--8<-- "projects/p1-logan/rock.expected"
```

To publish it you would tag the repository (`source.tag`) and run
`luarocks upload logan-1.0.0-1.rockspec --api-key=...`; we stop before that step.

## Step 8: lint

```lua title="projects/p1-logan/.luacheckrc"
--8<-- "projects/p1-logan/.luacheckrc"
```

```bash title="projects/p1-logan/luacheck.test.sh"
--8<-- "projects/p1-logan/luacheck.test.sh"
```

```text title="Output"
--8<-- "projects/p1-logan/luacheck.expected"
```

!!! info "Version notes"
    - The code avoids everything that differs between 5.1 (LuaJIT) and 5.4/5.5:
      no `//` or bitwise operators, no `utf8` library, no `<const>`, and files
      are read with `fh:lines()`, which behaves the same everywhere.
    - `string.format("%d", 3.0)` works on all three; `("%d"):format(2.5)` would
      fail on 5.4/5.5 ("number has no integer representation") but truncate on
      LuaJIT, which is why every `%d` argument here is integral by construction.
    - The rockspec says `lua >= 5.1, < 5.6`; LuaRocks maps LuaJIT to `5.1`.

## Extension exercises

??? example "Exercise 1: latency percentiles"
    The app log has durations like `(took 812ms)` (`rec.ms`). Print p50 and p95
    using the nearest-rank method (the value at rank `ceil(p/100 * n)`).

    ??? success "Solution"
        ```lua
        --8<-- "projects/p1-logan/exercises/ex1_percentiles.lua"
        ```
        ```text
        --8<-- "projects/p1-logan/exercises/ex1_percentiles.expected"
        ```

??? example "Exercise 2: a time window"
    Add `--since` / `--until` filtering. Hint: the minute keys sort correctly as strings.

    ??? success "Solution"
        ```lua
        --8<-- "projects/p1-logan/exercises/ex2_window.lua"
        ```
        ```text
        --8<-- "projects/p1-logan/exercises/ex2_window.expected"
        ```

??? example "Exercise 3: CSV output"
    Render the top lists as CSV, quoting fields with commas or quotes (RFC 4180).

    ??? success "Solution"
        ```lua
        --8<-- "projects/p1-logan/exercises/ex3_csv.lua"
        ```
        ```text
        --8<-- "projects/p1-logan/exercises/ex3_csv.expected"
        ```

??? example "Exercise 4: streaming input"
    Logs often arrive in chunks that split lines (a socket, `tail -f`). Write a
    feeder that buffers the unfinished tail and test it with odd chunk sizes.

    ??? success "Solution"
        ```lua
        --8<-- "projects/p1-logan/exercises/ex4_stream.lua"
        ```
        ```text
        --8<-- "projects/p1-logan/exercises/ex4_stream.expected"
        ```

## Quiz

??? question "Q1. Why does `logan.main` return a status instead of calling `os.exit`?"
    So tests can call it in-process with fake streams and check the status;
    `os.exit` would end the test run. Only the two-line `bin/logan` exits.

??? question "Q2. Lua patterns have no `|`. How does `logan` support two log formats?"
    One anchored pattern per format, tried in order in `parse.line` ("auto"), each
    returning `nil, reason` when it does not match.

??? question "Q3. Why must `report.top` break ties by key?"
    `pairs` order is unspecified and differs between interpreters (and runs);
    without a tie-breaker, equal counts would print in varying order.

??? question "Q4. Why not write `status // 100`?"
    `//` is Lua 5.3+ syntax; LuaJIT rejects the whole file at load time.
    `math.floor(status / 100)` works everywhere.

??? question "Q5. What does `install.bin` in the rockspec give you?"
    LuaRocks installs a wrapper command in the tree's `bin/` that sets the module
    paths for that tree and runs the script with the matching interpreter.
