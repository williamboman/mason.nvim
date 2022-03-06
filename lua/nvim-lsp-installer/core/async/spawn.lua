local a = require "nvim-lsp-installer.core.async"
local Result = require "nvim-lsp-installer.core.result"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"

local async_spawn = a.promisify(process.spawn)

---@type Record<string, fun(opts: JobSpawnOpts): Result>
local spawn = {
    aliases = {
        npm = platform.is_win and "npm.cmd" or "npm",
    },
}

local function Failure(err, cmd)
    return Result.failure(setmetatable(err, {
        __tostring = function()
            return ("spawn: %s failed with exit code %d"):format(cmd, err.exit_code)
        end,
    }))
end

setmetatable(spawn, {
    __index = function(self, k)
        return function(args)
            local cmd_args = {}
            for i, arg in ipairs(args) do
                cmd_args[i] = arg
            end
            ---@type JobSpawnOpts
            local spawn_args = {
                stdio_sink = args.stdio_sink,
                cwd = args.cwd,
                env = args.env,
                args = cmd_args,
            }

            local stdio
            if not spawn_args.stdio_sink then
                stdio = process.in_memory_sink()
                spawn_args.stdio_sink = stdio.sink
            end

            local cmd = self.aliases[k] or k
            local _, exit_code = async_spawn(cmd, spawn_args)

            if exit_code == 0 then
                return Result.success {
                    stdout = stdio and table.concat(stdio.buffers.stdout, "") or nil,
                    stderr = stdio and table.concat(stdio.buffers.stderr, "") or nil,
                }
            else
                return Failure({
                    exit_code = exit_code,
                    stdout = stdio and table.concat(stdio.buffers.stdout, "") or nil,
                    stderr = stdio and table.concat(stdio.buffers.stderr, "") or nil,
                }, cmd)
            end
        end
    end,
})

return spawn
