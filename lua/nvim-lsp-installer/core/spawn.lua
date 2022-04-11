local a = require "nvim-lsp-installer.core.async"
local Result = require "nvim-lsp-installer.core.result"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"

---@alias JobSpawn Record<string, async fun(opts: JobSpawnOpts): Result>
---@type JobSpawn
local spawn = {
    _aliases = {
        npm = platform.is_win and "npm.cmd" or "npm",
        gem = platform.is_win and "gem.cmd" or "gem",
        composer = platform.is_win and "composer.bat" or "composer",
    },
    -- Utility function for optionally including arguments.
    ---@generic T
    ---@param condition boolean
    ---@param value T
    ---@return T
    _when = function(condition, value)
        return condition and value or vim.NIL
    end,
}

local function Failure(err, cmd)
    return Result.failure(setmetatable(err, {
        __tostring = function()
            if err.exit_code ~= nil then
                return ("spawn: %s failed with exit code %d. %s"):format(cmd, err.exit_code, err.stderr or "")
            else
                return ("spawn: %s failed with no exit code. %s"):format(cmd, err.stderr or "")
            end
        end,
    }))
end

setmetatable(spawn, {
    __index = function(self, k)
        ---@param args string|nil|string[][]
        return function(args)
            local cmd_args = {}
            for _, arg in ipairs(args) do
                if type(arg) == "table" then
                    vim.list_extend(cmd_args, arg)
                elseif arg ~= vim.NIL then
                    cmd_args[#cmd_args + 1] = arg
                end
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

            local cmd = self._aliases[k] or k
            local _, exit_code = a.wait(function(resolve)
                local handle, stdio = process.spawn(cmd, spawn_args, resolve)
                if args.on_spawn and handle and stdio then
                    args.on_spawn(handle, stdio)
                end
            end)

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
