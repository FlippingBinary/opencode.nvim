local M = {}

---@alias opencode.status.Status
---| "idle"
---| "error"
---| "responding"
---| "requesting_permission"

---@alias opencode.status.Icon
---| "󰚩"
---| "󱜙"
---| "󱚟"
---| "󱚡"
---| "󱚧"

---@type table<string, opencode.status.Status>
M.statuses = {}

---@param cwd? string
---@return opencode.status.Icon
function M.statusline(cwd)
  cwd = cwd or require("opencode.config").get_project_root()
  local status = M.statuses[cwd]

  if status == "idle" then
    return "󰚩"
  elseif status == "responding" then
    return "󱜙"
  elseif status == "requesting_permission" then
    return "󱚟"
  elseif status == "error" then
    return "󱚡"
  else
    return "󱚧"
  end
end

---@param event opencode.cli.client.Event
---@param cwd string
function M.update(event, cwd)
  if
    event.type == "server.connected"
    or event.type == "session.idle"
    -- `session.idle` seems frequently followed by a few `message.updated`s...
    -- but `session.diff` seems to be a more definitive idle signal.
    -- It's sometimes also emitted in the middle of a response, but NBD.
    or event.type == "session.diff"
    -- Pretty good fallback
    or event.type == "session.heartbeat"
  then
    M.statuses[cwd] = "idle"
  elseif
    event.type == "message.updated"
    or event.type == "message.part.updated"
    or event.type == "permission.replied"
  then
    M.statuses[cwd] = "responding"
  elseif event.type == "permission.updated" then
    M.statuses[cwd] = "requesting_permission"
  elseif event.type == "session.error" then
    M.statuses[cwd] = "error"
  elseif event.type == "server.disconnected" then
    M.statuses[cwd] = nil
  end
end

return M
