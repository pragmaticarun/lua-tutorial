-- logan: a command-line log analyzer.
--   logan.main(argv, stdout, stderr, stdin) -> exit status
local args = require("logan.args")
local parse = require("logan.parse")
local report = require("logan.report")

local M = { _VERSION = "logan 1.0.0" }

M.spec = {
  usage = "logan [options] FILE... ('-' reads standard input)",
  options = {
    { "-f", "--format", arg = "FMT", default = "auto", choices = { "auto", "combined", "app" },
      help = "log format" },
    { "-n", "--top", arg = "N", default = "5", type = "number", help = "rows in each top list" },
    { "-s", "--status", arg = "LIST", help = "keep only these statuses, e.g. 4xx,500" },
    { "-o", "--output", arg = "KIND", default = "text", choices = { "text", "json" },
      help = "report format" },
    { nil, "--version", help = "print the version" },
    { "-h", "--help", help = "show this help" },
  },
}

-- "4xx,500" -> function(status) -> boolean
function M.status_filter(list)
  local wanted = {}
  for item in list:gmatch("[^,%s]+") do
    local class = item:match("^(%d)xx$")
    if class then wanted[#wanted + 1] = function(s) return math.floor(s / 100) == tonumber(class) end
    elseif tonumber(item) then wanted[#wanted + 1] = function(s) return s == tonumber(item) end
    else return nil, ("bad status '%s' (use 404 or 4xx)"):format(item) end
  end
  return function(status)
    for _, f in ipairs(wanted) do if f(status) then return true end end
    return false
  end
end

function M.main(argv, stdout, stderr, stdin)
  local opts, files = args.parse(M.spec, argv)
  if not opts then
    stderr:write("logan: ", files, "\n", "try 'logan --help'\n")
    return 2
  end
  if opts.help then stdout:write(args.help(M.spec), "\n"); return 0 end
  if opts.version then stdout:write(M._VERSION, " (", _VERSION, ")\n"); return 0 end
  if #files == 0 then stderr:write("logan: no input files\n"); return 2 end
  local keep
  if opts.status then
    local err
    keep, err = M.status_filter(opts.status)
    if not keep then stderr:write("logan: ", err, "\n"); return 2 end
  end

  local st, status = report.new(), 0
  for _, name in ipairs(files) do
    local fh, err = stdin, nil
    if name ~= "-" then fh, err = io.open(name, "r") end
    if not fh then
      stderr:write("logan: ", err, "\n"); status = 1
    else
      local n = 0
      for line in fh:lines() do
        n = n + 1
        local rec = parse.line(line, opts.format)
        if not (rec and keep and (rec.status == nil or not keep(rec.status))) then
          report.add(st, rec, name .. ":" .. n)
        end
      end
      if fh ~= stdin then fh:close() end
    end
  end
  local text = opts.output == "json" and report.json(st, opts.top) or report.text(st, opts.top)
  stdout:write(text, "\n")
  return status
end

return M
