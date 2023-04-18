local _ = require "mason-core.functional"
local a = require "mason-core.async"
local async_uv = require "mason-core.async.uv"
local installer = require "mason-core.installer"
local log = require "mason-core.log"
local platform = require "mason-core.platform"
local powershell = require "mason-core.managers.powershell"

local M = {}

---@class BuildInstruction
---@field target? Platform | Platform[]
---@field run string
---@field staged? boolean
---@field env? table<string, string>

---@async
---@param build BuildInstruction
---@return Result
---@nodiscard
function M.run(build)
    log.fmt_debug("build: run %s", build)
    local ctx = installer.context()
    if build.staged == false then
        ctx:promote_cwd()
    end
    return platform.when {
        unix = function()
            return ctx.spawn.bash {
                on_spawn = a.scope(function(_, stdio)
                    local stdin = stdio[1]
                    async_uv.write(stdin, "set -euxo pipefail;\n")
                    async_uv.write(stdin, build.run)
                    async_uv.shutdown(stdin)
                    async_uv.close(stdin)
                end),
                env = build.env,
            }
        end,
        win = function()
            return powershell.command(build.run, {
                env = build.env,
            }, ctx.spawn)
        end,
    }
end

return M
