local spawn = require "nvim-lsp-installer.core.spawn"
local process = require "nvim-lsp-installer.core.process"

local M = {}

local PWSHOPT = {
    progress_preference = [[ $ProgressPreference = 'SilentlyContinue'; ]], -- https://stackoverflow.com/a/63301751
    security_protocol = [[ [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ]],
}

---@param script string
---@param opts JobSpawnOpts
---@param custom_spawn JobSpawn
function M.script(script, opts, custom_spawn)
    opts = opts or {}
    ---@type JobSpawn
    local spawner = custom_spawn or spawn
    return spawner.powershell(vim.tbl_extend("keep", {
        "-NoProfile",
        on_spawn = function(_, stdio)
            local stdin = stdio[1]
            stdin:write(PWSHOPT.progress_preference)
            stdin:write(PWSHOPT.security_protocol)
            stdin:write(script)
            stdin:close()
        end,
        env_raw = process.graft_env(opts.env or {}, { "PSMODULEPATH" }),
    }, opts))
end

---@param command string
---@param opts JobSpawnOpts
---@param custom_spawn JobSpawn
function M.command(command, opts, custom_spawn)
    opts = opts or {}
    ---@type JobSpawn
    local spawner = custom_spawn or spawn
    return spawner.powershell(vim.tbl_extend("keep", {
        "-NoProfile",
        "-Command",
        PWSHOPT.progress_preference .. PWSHOPT.security_protocol .. command,
        env_raw = process.graft_env(opts.env or {}, { "PSMODULEPATH" }),
    }, opts))
end

return M
