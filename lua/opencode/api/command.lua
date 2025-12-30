local M = {}

---See available commands [here](https://github.com/sst/opencode/blob/dev/packages/opencode/src/cli/cmd/tui/event.ts).
---@alias opencode.Command
---| 'session.list'
---| 'session.new'
---| 'session.share'
---| 'session.interrupt'
---| 'session.compact'
---| 'session.page.up'
---| 'session.page.down'
---| 'session.half.page.up'
---| 'session.half.page.down'
---| 'session.first'
---| 'session.last'
---| 'session.undo'
---| 'session.redo'
---| 'prompt.submit'
---| 'prompt.clear'
---| 'agent.cycle'

---@class opencode.api.command.Opts
---@field cwd? string The project root directory to use.

---Command `opencode`.
---
---@param command opencode.Command|string The command to send. Can be built-in or reference your custom commands.
---@param opts? opencode.api.command.Opts
function M.command(command, opts)
  local config = require("opencode.config")
  local cwd = config.get_project_root({ cwd = opts and opts.cwd })

  require("opencode.cli.server")
    .get_port(cwd)
    :next(function(port)
      -- No need to register SSE here - commands don't trigger any.
      -- (except maybe the `input_*` commands? but no reason for user to use those).
      require("opencode.cli.client").tui_execute_command(command, port)
    end)
    :catch(function(err)
      vim.notify(err, vim.log.levels.ERROR, { title = "opencode" })
    end)
end

return M
