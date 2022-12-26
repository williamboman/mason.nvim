local a = require "mason-core.async"
local spawn = require "mason-core.spawn"
local process = require "mason-core.process"

local M = {}

local PWSHOPT = {
    progress_preference = [[ $ProgressPreference = 'SilentlyContinue'; ]], -- https://stackoverflow.com/a/63301751
    security_protocol = [[ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ]],
    error_action_preference = [[ $ErrorActionPreference = "Stop"; ]],
}

local powershell = vim.fn.executable "pwsh" == 1 and "pwsh" or "powershell"

---@param script string
---@param opts SpawnArgs?
---@param custom_spawn JobSpawn?
function M.script(script, opts, custom_spawn)
    opts = opts or {}
    ---@type JobSpawn
    local spawner = custom_spawn or spawn
    return spawner[powershell](vim.tbl_extend("keep", {
        "-NoProfile",
        on_spawn = a.scope(function(_, stdio)
            local stdin = stdio[1]
            local write = a.promisify(vim.loop.write)
            write(stdin, PWSHOPT.error_action_preference)
            write(stdin, PWSHOPT.progress_preference)
            write(stdin, PWSHOPT.security_protocol)
            write(stdin, script)
            stdin:shutdown()
        end),
        env_raw = process.graft_env(opts.env or {}, { "PSMODULEPATH" }),
    }, opts))
end

---@param command string
---@param opts SpawnArgs?
---@param custom_spawn JobSpawn?
function M.command(command, opts, custom_spawn)
    opts = opts or {}
    ---@type JobSpawn
    local spawner = custom_spawn or spawn
    return spawner[powershell](vim.tbl_extend("keep", {
        "-NoProfile",
        "-Command",
        PWSHOPT.error_action_preference .. PWSHOPT.progress_preference .. PWSHOPT.security_protocol .. command,
        env_raw = process.graft_env(opts.env or {}, { "PSMODULEPATH" }),
    }, opts))
end

return M
