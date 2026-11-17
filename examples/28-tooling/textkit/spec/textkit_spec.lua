-- host: busted
-- busted specs: describe/it blocks with luassert's assert.* matchers.
local textkit = require("textkit")

describe("textkit", function()
  describe("trim", function()
    it("removes surrounding whitespace", function()
      assert.are.equal("hi there", textkit.trim("  hi there\t\n"))
    end)

    it("leaves inner whitespace alone", function()
      assert.are.equal("a  b", textkit.trim("a  b"))
    end)
  end)

  describe("slugify", function()
    it("lower-cases and joins words with dashes", function()
      assert.are.equal("hello-lua-world", textkit.slugify("Hello, Lua World!"))
    end)

    it("returns an empty string for punctuation only", function()
      assert.are.equal("", textkit.slugify("?!"))
    end)
  end)

  describe("split", function()
    it("keeps empty fields", function()
      assert.are.same({ "a", "", "b" }, textkit.split("a,,b", ","))
    end)

    it("treats the separator as plain text", function()
      assert.are.same({ "1", "2" }, textkit.split("1.2", "."))
    end)

    it("rejects an empty separator", function()
      assert.has_error(function()
        textkit.split("abc", "")
      end, "separator must not be empty")
    end)
  end)
end)
