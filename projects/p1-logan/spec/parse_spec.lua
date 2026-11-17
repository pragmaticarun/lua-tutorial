local parse = require("logan.parse")

describe("logan.parse", function()
  local access = '203.0.113.7 - - [17/Nov/2026:10:04:59 +0000] "GET /api/streams/42?token=abc HTTP/1.1" '
    .. '304 - "-" "mpv 0.42.0"'

  it("parses a combined access-log line", function()
    local r = parse.combined(access)
    assert.same({
      kind = "access", ip = "203.0.113.7", method = "GET", path = "/api/streams/42",
      status = 304, bytes = 0, referer = "-", agent = "mpv 0.42.0", minute = "2026-11-17 10:04",
    }, r)
  end)

  it("parses an application-log line, with and without a duration", function()
    local r = parse.app("2026-11-17T10:00:27Z ERROR [db] slow query (took 812ms)")
    assert.equal("ERROR", r.level)
    assert.equal("db", r.component)
    assert.equal(812, r.ms)
    assert.is_nil(parse.app("2026-11-17T10:00:27Z INFO [auth] login ok").ms)
  end)

  it("auto-detects the format and explains failures", function()
    assert.equal("access", parse.line(access).kind)
    assert.equal("app", parse.line("2026-11-17T10:00:00Z INFO [x] hi").kind)
    assert.same({ nil, "unrecognised line" }, { parse.line("garbage") })
    assert.same({ nil, "not an app log line" }, { parse.line(access, "app") })
  end)

  it("rejects an unknown month", function()
    local bad = access:gsub("Nov", "Nox")
    assert.same({ nil, "bad timestamp '17/Nox/2026:10:04:59 +0000'" }, { parse.combined(bad) })
  end)
end)
