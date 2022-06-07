local a = require "nvim-lsp-installer.core.async"
local Result = require "nvim-lsp-installer.core.result"
local process = require "nvim-lsp-installer.core.process"
local platform = require "nvim-lsp-installer.core.platform"
local functional = require "nvim-lsp-installer.core.functional"
local log = require "nvim-lsp-installer.log"

---@alias JobSpawn table<string, async fun(opts: JobSpawnOpts): Result>
---@type JobSpawn
local spawn = {
    _aliases = {
        npm = platform.is_win and "npm.cmd" or "npm",
        gem = platform.is_win and "gem.cmd" or "gem",
        composer = platform.is_win and "composer.bat" or "composer",
        gradlew = platform.is_win and "gradlew.bat" or "gradlew",
        -- for hererocks installations
        luarocks = (platform.is_win and vim.fn.executable "luarocks.bat" == 1) and "luarocks.bat" or "luarocks",
    },
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

local function parse_args(args, dest)
    for _, arg in ipairs(args) do
        if type(arg) == "table" then
            parse_args(arg, dest)
        elseif arg ~= vim.NIL then
            dest[#dest + 1] = arg
        end
    end
    return dest
end

local is_executable = functional.memoize(function(cmd)
    if vim.in_fast_event() then
        a.scheduler()
    end
    return vim.fn.executable(cmd) == 1
end, functional.identity)

---@class SpawnArgs
---@field with_paths string[] @Optional. Paths to add to the PATH environment variable.
---@field env table<string, string> @Optional. Example { SOME_ENV = "value", SOME_OTHER_ENV = "some_value" }
---@field env_raw string[] @Optional. Example: { "SOME_ENV=value", "SOME_OTHER_ENV=some_value" }
---@field stdio_sink StdioSink @Optional. If provided, will be used to write to stdout and stderr.
---@field cwd string @Optional
---@field on_spawn fun(handle: luv_handle, stdio: luv_pipe[]) @Optional. Will be called when the process successfully spawns.
---@field check_executable boolean @Optional. Whether to check if the provided command is executable (defaults to true).

setmetatable(spawn, {
    ---@param normalized_cmd string
    __index = function(self, normalized_cmd)
        ---@param args SpawnArgs
        return function(args)
            local cmd_args = {}
            parse_args(args, cmd_args)

            local env = args.env

            if args.with_paths then
                env = env or {}
                env.PATH = process.extend_path(args.with_paths)
            end

            ---@type JobSpawnOpts
            local spawn_args = {
                stdio_sink = args.stdio_sink,
                cwd = args.cwd,
                env = env and process.graft_env(env) or args.env_raw,
                args = cmd_args,
            }

            local stdio
            if not spawn_args.stdio_sink then
                stdio = process.in_memory_sink()
                spawn_args.stdio_sink = stdio.sink
            end

            local cmd = self._aliases[normalized_cmd] or normalized_cmd

            if (env and env.PATH) == nil and args.check_executable ~= false and not is_executable(cmd) then
                log.fmt_debug("%s is not executable", cmd)
                return Failure({
                    stderr = ("%s is not executable"):format(cmd),
                }, cmd)
            end

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
