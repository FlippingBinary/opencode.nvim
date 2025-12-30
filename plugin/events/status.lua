vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("OpencodeStatus", { clear = true }),
  pattern = "OpencodeEvent:*",
  callback = function(args)
    ---@type opencode.cli.client.Event
    local event = args.data.event
    local cwd = args.data.cwd
    require("opencode.status").update(event, cwd)
  end,
  desc = "Update opencode status",
})
