local a = require "mason.core.async"
local spawn = require "mason.core.spawn"
local _ = require "mason.core.functional"
local process = require "mason.core.process"
local EventEmitter = require "mason.core.EventEmitter"
local log = require "mason.log"
local Optional = require "mason.core.optional"
local platform = require "mason.core.platform"

local uv = vim.loop

---@alias InstallHandleState
--- | '"IDLE"'
--- | '"QUEUED"'
--- | '"ACTIVE"'
--- | '"CLOSED"'

---@class InstallHandleSpawnInfo
---@field handle luv_handle
---@field pid integer
---@field cmd string
---@field args string[]
local InstallHandleSpawnInfo = {}
InstallHandleSpawnInfo.__index = InstallHandleSpawnInfo

---@param fields InstallHandleSpawnInfo
function InstallHandleSpawnInfo.new(fields)
    return setmetatable(fields, InstallHandleSpawnInfo)
end

function InstallHandleSpawnInfo:__tostring()
    return ("%s %s"):format(self.cmd, table.concat(self.args, " "))
end

---@class InstallHandle : EventEmitter
---@field package Package
---@field state InstallHandleState
---@field stdio { buffers: { stdout: string[], stderr: string[] }, sink: StdioSink  }
---@field is_terminated boolean
---@field private spawninfo_stack InstallHandleSpawnInfo[]
local InstallHandle = setmetatable({}, { __index = EventEmitter })
local InstallHandleMt = { __index = InstallHandle }

---@param handle InstallHandle
local function new_sink(handle)
    local stdout, stderr = {}, {}
    return {
        buffers = { stdout = stdout, stderr = stderr },
        sink = {
            stdout = function(chunk)
                stdout[#stdout + 1] = chunk
                handle:emit("stdout", chunk)
            end,
            stderr = function(chunk)
                stderr[#stderr + 1] = chunk
                handle:emit("stderr", chunk)
            end,
        },
    }
end

---@param pkg Package
function InstallHandle.new(pkg)
    local self = EventEmitter.init(setmetatable({}, InstallHandleMt))
    self.state = "IDLE"
    self.package = pkg
    self.spawninfo_stack = {}
    self.stdio = new_sink(self)
    self.is_terminated = false
    return self
end

---@param luv_handle luv_handle
---@param pid integer
---@param cmd string
---@param args string[]
function InstallHandle:push_spawninfo(luv_handle, pid, cmd, args)
    local spawninfo = InstallHandleSpawnInfo.new {
        handle = luv_handle,
        pid = pid,
        cmd = cmd,
        args = args,
    }
    log.fmt_trace("Pushing spawninfo stack for %s: %s (pid: %s)", self, spawninfo, pid)
    self.spawninfo_stack[#self.spawninfo_stack + 1] = spawninfo
    self:emit "spawninfo:change"
end

---@param luv_handle luv_handle
function InstallHandle:pop_spawninfo(luv_handle)
    for i = #self.spawninfo_stack, 1, -1 do
        if self.spawninfo_stack[i].handle == luv_handle then
            log.fmt_trace("Popping spawninfo stack for %s: %s", self, self.spawninfo_stack[i])
            table.remove(self.spawninfo_stack, i)
            self:emit "spawninfo:change"
            return true
        end
    end
    return false
end

---@return Optional @Optional<InstallHandleSpawnInfo>
function InstallHandle:peek_spawninfo_stack()
    return Optional.of_nilable(self.spawninfo_stack[#self.spawninfo_stack])
end

function InstallHandle:is_idle()
    return self.state == "IDLE"
end

function InstallHandle:is_queued()
    return self.state == "QUEUED"
end

function InstallHandle:is_active()
    return self.state == "ACTIVE"
end

function InstallHandle:is_closed()
    return self.state == "CLOSED"
end

---@param new_state InstallHandleState
function InstallHandle:set_state(new_state)
    local old_state = self.state
    self.state = new_state
    log.fmt_trace("Changing %s state from %s to %s", self, old_state, new_state)
    self:emit("state:change", new_state, old_state)
end

---@param signal integer
function InstallHandle:kill(signal)
    assert(not self:is_closed(), "Cannot kill closed handle.")
    log.fmt_trace("Sending signal %s to luv handles in %s", signal, self)
    for _, spawninfo in pairs(self.spawninfo_stack) do
        process.kill(spawninfo.handle, signal)
    end
    self:emit("kill", signal)
end

---@param pid integer
local win_taskkill = a.scope(function(pid)
    spawn.taskkill {
        "/f",
        "/t",
        "/pid",
        pid,
    }
end)

function InstallHandle:terminate()
    assert(not self:is_closed(), "Cannot terminate closed handle.")
    if self.is_terminated then
        log.fmt_trace("Handle is already terminated %s", self)
        return
    end
    log.fmt_trace("Terminating %s", self)
    -- https://github.com/libuv/libuv/issues/1133
    if platform.is.win then
        for _, spawninfo in ipairs(self.spawninfo_stack) do
            win_taskkill(spawninfo.pid)
        end
    else
        self:kill(15) -- SIGTERM
    end
    self.is_terminated = true
    self:emit "terminate"
    local check = uv.new_check()
    check:start(function()
        for _, spawninfo in ipairs(self.spawninfo_stack) do
            local luv_handle = spawninfo.handle
            local ok, is_closing = pcall(luv_handle.is_closing, luv_handle)
            if ok and not is_closing then
                return
            end
        end
        check:stop()
        if not self:is_closed() then
            self:close()
        end
    end)
end

function InstallHandle:queued()
    assert(self:is_idle(), "Can only queue idle handles.")
    self:set_state "QUEUED"
end

function InstallHandle:active()
    assert(self:is_idle() or self:is_queued(), "Can only activate idle or queued handles.")
    self:set_state "ACTIVE"
end

function InstallHandle:close()
    log.fmt_trace("Closing %s", self)
    assert(not self:is_closed(), "Handle is already closed.")
    for _, spawninfo in ipairs(self.spawninfo_stack) do
        local luv_handle = spawninfo.handle
        local ok, is_closing = pcall(luv_handle.is_closing, luv_handle)
        if ok then
            assert(is_closing, "There are open libuv handles.")
        end
    end
    self.spawninfo_stack = {}
    self:set_state "CLOSED"
    self:emit "closed"
    self:clear_event_handlers()
end

function InstallHandleMt:__tostring()
    return ("InstallHandle(package=%s, state=%s)"):format(self.package, self.state)
end

return InstallHandle
