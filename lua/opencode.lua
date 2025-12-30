---`opencode.nvim` public API.
local M = {}

M.ask = require("opencode.ui.ask").ask
M.select = require("opencode.ui.select").select

M.prompt = require("opencode.api.prompt").prompt
M.operator = require("opencode.api.operator").operator
M.command = require("opencode.api.command").command

---@class opencode.provider.action.Opts
---@field cwd? string The project root directory to use.

---@param opts? opencode.provider.action.Opts
function M.toggle(opts)
  local cwd = require("opencode.config").get_project_root({ cwd = opts and opts.cwd })
  require("opencode.provider").toggle(cwd)
end

---@param opts? opencode.provider.action.Opts
function M.start(opts)
  local cwd = require("opencode.config").get_project_root({ cwd = opts and opts.cwd })
  require("opencode.provider").start(cwd)
end

---@param opts? opencode.provider.action.Opts
function M.stop(opts)
  local cwd = require("opencode.config").get_project_root({ cwd = opts and opts.cwd })
  require("opencode.provider").stop(cwd)
end

M.statusline = require("opencode.status").statusline

return M
