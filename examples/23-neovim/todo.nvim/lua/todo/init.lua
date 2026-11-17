-- module
-- lua/todo/init.lua: require("todo") finds this file on 'runtimepath'.
local M = {}

local defaults = {
  keywords = { TODO = "Todo", FIXME = "ErrorMsg", NOTE = "Comment" },
  auto = true,  -- re-highlight on BufEnter / TextChanged
}
M.config = vim.deepcopy(defaults)

-- one namespace for all our extmarks: easy to clear in one call
local ns = vim.api.nvim_create_namespace("todo")
M.ns = ns

--- Find keywords in a buffer.
---@param buf integer buffer handle (0 = current)
---@return {lnum: integer, col: integer, keyword: string, text: string}[]
function M.scan(buf)
  local items = {}
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, line in ipairs(lines) do
    for kw in pairs(M.config.keywords) do
      local s = line:find("%f[%w]" .. kw .. ":")
      if s then
        items[#items + 1] = {
          lnum = i, col = s, keyword = kw,
          text = vim.trim(line:sub(s + #kw + 1)),
        }
      end
    end
  end
  table.sort(items, function(a, b) return a.lnum < b.lnum end)
  return items
end

--- Highlight keywords with extmarks; clear = true removes them.
function M.highlight(buf, clear)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if clear then return 0 end
  local items = M.scan(buf)
  for _, it in ipairs(items) do
    vim.api.nvim_buf_set_extmark(buf, ns, it.lnum - 1, it.col - 1, {
      end_col = it.col - 1 + #it.keyword,
      hl_group = M.config.keywords[it.keyword],
    })
  end
  return #items
end

--- Fill the quickfix list from every loaded buffer.
function M.to_quickfix()
  local qf = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      for _, it in ipairs(M.scan(buf)) do
        qf[#qf + 1] = { bufnr = buf, lnum = it.lnum, col = it.col,
                        text = it.keyword .. ": " .. it.text,
                        type = it.keyword == "FIXME" and "E" or "I" }
      end
    end
  end
  vim.fn.setqflist({}, " ", { title = "TODOs", items = qf })
  return #qf
end

--- Configure the plugin. Safe to call more than once.
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  local group = vim.api.nvim_create_augroup("todo", { clear = true })
  if M.config.auto then
    vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
      group = group,
      callback = function(args) M.highlight(args.buf) end,
    })
  end
end

return M
