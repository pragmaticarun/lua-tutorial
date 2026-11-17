-- plugin/notes.lua: sourced at startup. Keep it tiny: define the commands,
-- and load the real code (lua/notes/) only when one is used.
if vim.g.loaded_notes then return end
vim.g.loaded_notes = true

vim.api.nvim_create_user_command("Notes", function()
  require("notes").open()
end, { desc = "Open this project's notes in a floating window" })

vim.api.nvim_create_user_command("NoteAdd", function(opts)
  require("notes").add_task(opts.args)
end, { nargs = "+", desc = "Add a task to this project's notes" })

vim.api.nvim_create_user_command("Tasks", function(opts)
  require("notes").pick(opts.fargs)
end, {
  nargs = "*",
  desc = "Pick from this project's tasks (optionally only those with all given #tags)",
  complete = function(arglead)
    return vim.tbl_filter(function(t) return vim.startswith(t, arglead) end, require("notes").tags())
  end,
})
