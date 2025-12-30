---@module 'snacks.terminal'

---Provide an integrated `opencode`.
---Providers should ignore manually-started `opencode` instances,
---operating only on those they start themselves.
---@class opencode.Provider
---
---The name of the provider.
---@field name? string
---
---The command to start `opencode`.
---The `--port` flag _must_ be present to expose the server for `opencode.nvim` to connect to.
---`opencode.nvim` will set `--port <opts.port>` if present.
---See all available flags [here](https://opencode.ai/docs/cli/#flags).
---@field cmd? string
---
---The cwd this provider instance is for.
---@field cwd? string
---
---@field new? fun(opts: table, cwd: string): opencode.Provider
---
---Toggle `opencode`.
---@field toggle? fun(self: opencode.Provider)
---
---Start `opencode`.
---Called when attempting to interact with `opencode` but none was found.
---`opencode.nvim` then polls for a couple seconds waiting for one to appear.
---Should not steal focus by default, if possible.
---@field start? fun(self: opencode.Provider)
---
---Stop the previously started `opencode`.
---Called when Neovim is exiting.
---@field stop? fun(self: opencode.Provider)
---
---Health check for the provider.
---Should return `true` if the provider is available,
---else a reason string and optional advice (for `vim.health.warn`).
---@field health? fun(): boolean|string, ...string|string[]

---Configure and enable built-in providers.
---@class opencode.provider.Opts
---
---The built-in provider to use, or `false` for none.
---Default order:
---  - `"snacks"` if `snacks.terminal` is available and enabled
---  - `"kitty"` if in a `kitty` session with remote control enabled
---  - `"wezterm"` if in a `wezterm` window
---  - `"tmux"` if in a `tmux` session
---  - `"terminal"` as a fallback
---@field enabled? "terminal"|"snacks"|"kitty"|"wezterm"|"tmux"|false
---
---@field terminal? opencode.provider.terminal.Opts
---@field snacks? opencode.provider.snacks.Opts
---@field kitty? opencode.provider.kitty.Opts
---@field wezterm? opencode.provider.wezterm.Opts
---@field tmux? opencode.provider.tmux.Opts

local M = {}

local provider_instances = {}

---Get all providers.
---@return opencode.Provider[]
function M.list()
  return {
    require("opencode.provider.snacks"),
    require("opencode.provider.kitty"),
    require("opencode.provider.wezterm"),
    require("opencode.provider.tmux"),
    require("opencode.provider.terminal"),
  }
end

---Toggle `opencode` via the configured provider.
---@param cwd string
---@return opencode.Provider|nil
function M.get_or_create(cwd)
  if provider_instances[cwd] then
    return provider_instances[cwd]
  end

  local config = require("opencode.config")
  local provider_or_opts = config.opts.provider

  if not provider_or_opts then
    return nil
  end

  local provider

  if provider_or_opts.toggle or provider_or_opts.start or provider_or_opts.stop then
    ---@cast provider_or_opts opencode.Provider
    provider = provider_or_opts
    provider.cwd = cwd
  elseif provider_or_opts.enabled then
    local ok, resolved_provider = pcall(require, "opencode.provider." .. provider_or_opts.enabled)
    if not ok then
      vim.notify(
        "Failed to load `opencode` provider '" .. provider_or_opts.enabled .. "': " .. resolved_provider,
        vim.log.levels.ERROR,
        { title = "opencode" }
      )
      return nil
    end

    local resolved_provider_opts = provider_or_opts[provider_or_opts.enabled]
    provider = resolved_provider.new(resolved_provider_opts, cwd)
    provider.cmd = provider.cmd or provider_or_opts.cmd
  end

  if provider then
    local port = config.opts.port
    if port and provider.cmd and not provider.cmd:find("--port") then
      provider.cmd = provider.cmd .. " --port " .. tostring(port)
    end

    provider_instances[cwd] = provider
  end

  return provider
end

---@param cwd string
function M.toggle(cwd)
  local provider = M.get_or_create(cwd)
  if provider and provider.toggle then
    provider:toggle()
    require("opencode.events").subscribe(cwd)
  else
    error("`provider.toggle` unavailable — run `:checkhealth opencode` for details", 0)
  end
end

---Start `opencode` via the configured provider.
---@param cwd string
function M.start(cwd)
  local provider = M.get_or_create(cwd)
  if provider and provider.start then
    provider:start()
    require("opencode.events").subscribe(cwd)
  else
    error("`provider.start` unavailable — run `:checkhealth opencode` for details", 0)
  end
end

---Stop `opencode` via the configured provider.
---@param cwd string
function M.stop(cwd)
  local provider = provider_instances[cwd]
  if provider and provider.stop then
    provider:stop()
    require("opencode.events").unsubscribe(cwd)
    provider_instances[cwd] = nil
  else
    error("`provider.stop` unavailable — run `:checkhealth opencode` for details", 0)
  end
end

function M.stop_all()
  for _, provider in pairs(provider_instances) do
    if provider and provider.stop then
      provider:stop()
    end
  end
  provider_instances = {}
  require("opencode.events").unsubscribe_all()
end

---@return table<string, opencode.Provider>
function M.get_instances()
  return provider_instances
end

return M
