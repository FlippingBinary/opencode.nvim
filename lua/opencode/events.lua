local M = {}

---@class opencode.events.Opts
---
---Whether to subscribe to Server-Sent Events (SSE) from `opencode` and execute `OpencodeEvent:<event.type>` autocmds.
---@field enabled? boolean
---
---Reload buffers edited by `opencode` in real-time.
---Requires `vim.o.autoread = true`.
---@field reload? boolean
---
---@field permissions? opencode.events.permissions.Opts

local heartbeat_timers = {}
local OPENCODE_HEARTBEAT_INTERVAL_MS = 30000

---Subscribe to `opencode`'s Server-Sent Events (SSE) to execute `OpencodeEvent:<event.type>` autocmds.
---@param cwd string
function M.subscribe(cwd)
  if not require("opencode.config").opts.events.enabled then
    return
  end

  require("opencode.cli.server")
    .get_port(cwd, false)
    :next(function(port)
      if not heartbeat_timers[cwd] then
        heartbeat_timers[cwd] = vim.uv.new_timer()
      end

      require("opencode.cli.client").sse_subscribe(
        cwd,
        port,
        ---@param response opencode.cli.client.Event
        ---@param event_cwd string
        function(response, event_cwd)
          local timer = heartbeat_timers[event_cwd]
          if timer then
            timer:stop()
            timer:start(
              OPENCODE_HEARTBEAT_INTERVAL_MS + 5000,
              0,
              vim.schedule_wrap(function()
                M.unsubscribe(event_cwd)
              end)
            )
          end

          vim.api.nvim_exec_autocmds("User", {
            pattern = "OpencodeEvent:" .. response.type,
            data = {
              event = response,
              port = port,
              cwd = event_cwd,
            },
          })
        end
      )
    end)
    :catch(function(err)
      vim.notify("Failed to subscribe to SSE: " .. err, vim.log.levels.WARN)
    end)
end

---@param cwd string
function M.unsubscribe(cwd)
  local timer = heartbeat_timers[cwd]
  if timer then
    timer:stop()
    heartbeat_timers[cwd] = nil
  end
  require("opencode.cli.client").sse_unsubscribe(cwd)

  vim.api.nvim_exec_autocmds("User", {
    pattern = "OpencodeEvent:server.disconnected",
    data = {
      event = {
        type = "server.disconnected",
      },
      cwd = cwd,
    },
  })
end

function M.unsubscribe_all()
  for cwd, timer in pairs(heartbeat_timers) do
    timer:stop()
  end
  heartbeat_timers = {}
  require("opencode.cli.client").sse_unsubscribe_all()
end

return M
