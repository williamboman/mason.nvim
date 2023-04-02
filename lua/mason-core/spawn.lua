local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local a = require "mason-core.async"
local log = require "mason-core.log"
local platform = require "mason-core.platform"
local process = require "mason-core.process"

---@alias JobSpawn table<string, async fun(opts: SpawnArgs): Result>
---@type JobSpawn
local spawn = {
    _aliases = {
        npm = platform.is.win and "npm.cmd" or "npm",
        gem = platform.is.win and "gem.cmd" or "gem",
        composer = platform.is.win and "composer.bat" or "composer",
        gradlew = platform.is.win and "gradlew.bat" or "gradlew",
        -- for hererocks installations
        luarocks = (platform.is.win and vim.fn.executable "luarocks.bat" == 1) and "luarocks.bat" or "luarocks",
        rebar3 = platform.is.win and "rebar3.cmd" or "rebar3",
    },
    _flatten_cmd_args = _.compose(_.filter(_.complement(_.equals(vim.NIL))), _.flatten),
}

local function Failure(err, cmd)
    return Result.failure(setmetatable(err, {
        __tostring = function()
            return ("spawn: %s failed with exit code %s and signal %s. %s"):format(
                cmd,
                err.exit_code or "-",
                err.signal or "-",
                err.stderr or ""
            )
        end,
    }))
end

local is_executable = _.memoize(function(cmd)
    a.scheduler()
    return vim.fn.executable(cmd) == 1
end, _.identity)

---@class SpawnArgs
---@field with_paths string[]? Paths to add to the PATH environment variable.
---@field env table<string, string>? Example { SOME_ENV = "value", SOME_OTHER_ENV = "some_value" }
---@field env_raw string[]? Example: { "SOME_ENV=value", "SOME_OTHER_ENV=some_value" }
---@field stdio_sink StdioSink? If provided, will be used to write to stdout and stderr.
---@field cwd string?
---@field on_spawn (fun(handle: luv_handle, stdio: luv_pipe[], pid: integer))? Will be called when the process successfully spawns.
---@field check_executable boolean? Whether to check if the provided command is executable (defaults to true).

setmetatable(spawn, {
    ---@param normalized_cmd string
    __index = function(self, normalized_cmd)
        ---@param args SpawnArgs
        return function(args)
            local cmd_args = self._flatten_cmd_args(args)
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

            local _, exit_code, signal = a.wait(function(resolve)
                local handle, stdio, pid = process.spawn(cmd, spawn_args, resolve)
                if args.on_spawn and handle and stdio and pid then
                    args.on_spawn(handle, stdio, pid)
                end
            end)

            if exit_code == 0 and signal == 0 then
                return Result.success {
                    stdout = stdio and table.concat(stdio.buffers.stdout, "") or nil,
                    stderr = stdio and table.concat(stdio.buffers.stderr, "") or nil,
                }
            else
                return Failure({
                    exit_code = exit_code,
                    signal = signal,
                    stdout = stdio and table.concat(stdio.buffers.stdout, "") or nil,
                    stderr = stdio and table.concat(stdio.buffers.stderr, "") or nil,
                }, cmd)
            end
        end
    end,
})

return spawn
