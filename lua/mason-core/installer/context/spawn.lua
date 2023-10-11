local spawn = require "mason-core.spawn"

---@class InstallContextSpawn
---@field strict_mode boolean Whether spawn failures should raise an exception rather then return a Result.
---@field private cwd InstallContextCwd
---@field private handle InstallHandle
---@field [string] async fun(opts: SpawnArgs): Result
local InstallContextSpawn = {}

---@param cwd InstallContextCwd
---@param handle InstallHandle
---@param strict_mode boolean
function InstallContextSpawn.new(cwd, handle, strict_mode)
    return setmetatable({ cwd = cwd, handle = handle, strict_mode = strict_mode }, InstallContextSpawn)
end

---@param cmd string
function InstallContextSpawn:__index(cmd)
    ---@param args JobSpawnOpts
    return function(args)
        args.cwd = args.cwd or self.cwd:get()
        args.stdio_sink = args.stdio_sink or self.handle.stdio.sink
        local on_spawn = args.on_spawn
        local captured_handle
        args.on_spawn = function(handle, stdio, pid, ...)
            captured_handle = handle
            self.handle:register_spawn_handle(handle, pid, cmd, spawn._flatten_cmd_args(args))
            if on_spawn then
                on_spawn(handle, stdio, pid, ...)
            end
        end
        local function pop_spawn_stack()
            if captured_handle then
                self.handle:deregister_spawn_handle(captured_handle)
            end
        end
        local result = spawn[cmd](args):on_success(pop_spawn_stack):on_failure(pop_spawn_stack)
        if self.strict_mode then
            return result:get_or_throw()
        else
            return result
        end
    end
end

return InstallContextSpawn
