-- host: nvim
-- User commands with arguments, ranges, bang and completion.
-- In headless `nvim -l`, print() goes to Neovim's message area (stderr);
-- write test output to stdout explicitly.
local function say(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
  io.write(table.concat(parts, " "), "\n")
end

local api = vim.api
local buf = api.nvim_create_buf(false, true)
api.nvim_set_current_buf(buf)
api.nvim_buf_set_lines(buf, 0, -1, true, { "alpha beta", "gamma", "delta epsilon zeta", "eta" })

-- :WordCount [range]  counts words in the range (default: whole buffer)
api.nvim_create_user_command("WordCount", function(opts)
  local lines = api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, true)
  local n = 0
  for _, l in ipairs(lines) do for _ in l:gmatch("%S+") do n = n + 1 end end
  say(("lines %d-%d: %d words"):format(opts.line1, opts.line2, n))
end, { range = "%", desc = "Count words" })

-- :Greet[!] {name}  with completion; opts.fargs splits, opts.args is raw
api.nvim_create_user_command("Greet", function(opts)
  local msg = "hello, " .. opts.args
  if opts.bang then msg = msg:upper() end
  say(msg, "(fargs=" .. #opts.fargs .. ")")
end, {
  nargs = "+",
  bang = true,
  complete = function(arglead) -- (ArgLead, CmdLine, CursorPos)
    return vim.tbl_filter(function(n) return n:find(arglead, 1, true) == 1 end,
      { "world", "neovim", "nvim-team" })
  end,
})

vim.cmd("WordCount")
vim.cmd("2,3WordCount")
vim.cmd.WordCount({ range = { 4, 4 } })   -- the structured form of :4WordCount
vim.cmd("Greet world")
vim.cmd("Greet! big world")

-- completion is what <Tab> on the command line would offer
say("complete 'Greet n':", vim.inspect(vim.fn.getcompletion("Greet n", "cmdline")))

-- errors in a command surface as Lua errors you can pcall
local ok, err = pcall(vim.cmd, "Greet")
say("no args:", ok, (err:gsub("^.-(E%d+)", "%1")))

-- commands are listed in nvim_get_commands
local info = api.nvim_get_commands({})["WordCount"]
say("WordCount: range=" .. info.range .. " desc=" .. info.definition)
api.nvim_del_user_command("Greet")
say("Greet exists:", vim.fn.exists(":Greet") == 2)
