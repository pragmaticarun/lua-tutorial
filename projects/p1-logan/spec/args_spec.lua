local args = require("logan.args")

describe("logan.args", function()
  local spec = {
    usage = "t [options] FILE...",
    options = {
      { "-n", "--top", arg = "N", default = "5", type = "number" },
      { "-o", "--output", arg = "KIND", default = "text", choices = { "text", "json" } },
      { "-v", "--verbose" },
    },
  }

  it("fills in defaults", function()
    local opts, files = args.parse(spec, {})
    assert.same({ top = 5, output = "text", verbose = false }, opts)
    assert.same({}, files)
  end)

  it("accepts every option spelling", function()
    for _, argv in ipairs({ { "-n", "3" }, { "-n3" }, { "--top", "3" }, { "--top=3" } }) do
      assert.equal(3, (args.parse(spec, argv)).top)
    end
  end)

  it("keeps positional arguments in order, '-' included", function()
    local _, files = args.parse(spec, { "a.log", "-v", "-", "--", "-n" })
    assert.same({ "a.log", "-", "-n" }, files)
  end)

  it("reports mistakes instead of raising", function()
    assert.same({ nil, "unknown option '--colour'" }, { args.parse(spec, { "--colour" }) })
    assert.same({ nil, "option -n needs a value (N)" }, { args.parse(spec, { "-n" }) })
    assert.same({ nil, "option --top expects a number, got 'many'" }, { args.parse(spec, { "--top=many" }) })
    assert.same({ nil, "option --output must be one of text, json, got 'xml'" },
      { args.parse(spec, { "-o", "xml" }) })
    assert.same({ nil, "option --verbose takes no value" }, { args.parse(spec, { "--verbose=yes" }) })
  end)
end)
