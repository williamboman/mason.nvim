local a = require "mason-core.async"

---@class Condvar
local Condvar = {}
Condvar.__index = Condvar

function Condvar.new()
    return setmetatable({ handles = {} }, Condvar)
end

---@async
function Condvar:wait()
    a.wait(function(resolve)
        self.handles[#self.handles + 1] = resolve
    end)
end

function Condvar:notify()
    local handle = table.remove(self.handles)
    pcall(handle)
end

function Condvar:notify_all()
    while #self.handles > 0 do
        self:notify()
    end
    self.handles = {}
end

---@class Permit
local Permit = {}
Permit.__index = Permit

function Permit.new(semaphore)
    return setmetatable({ semaphore = semaphore }, Permit)
end

function Permit:forget()
    local semaphore = self.semaphore
    semaphore.permits = semaphore.permits + 1

    if semaphore.permits > 0 and #semaphore.handles > 0 then
        semaphore.permits = semaphore.permits - 1
        local release = table.remove(semaphore.handles, 1)
        release(Permit.new(semaphore))
    end
end

---@class Semaphore
local Semaphore = {}
Semaphore.__index = Semaphore

---@param permits integer
function Semaphore.new(permits)
    return setmetatable({ permits = permits, handles = {} }, Semaphore)
end

---@async
function Semaphore:acquire()
    if self.permits > 0 then
        self.permits = self.permits - 1
    else
        return a.wait(function(resolve)
            table.insert(self.handles, resolve)
        end)
    end

    return Permit.new(self)
end

---@class OneShotChannel
---@field has_sent boolean
---@field value any
---@field condvar Condvar
local OneShotChannel = {}
OneShotChannel.__index = OneShotChannel

function OneShotChannel.new()
    return setmetatable({
        has_sent = false,
        value = nil,
        condvar = Condvar.new(),
    }, OneShotChannel)
end

function OneShotChannel:is_closed()
    return self.has_sent
end

function OneShotChannel:send(...)
    assert(not self.has_sent, "Oneshot channel can only send once.")
    self.has_sent = true
    self.value = { ... }
    self.condvar:notify_all()
    self.condvar = nil
end

function OneShotChannel:receive()
    if not self.has_sent then
        self.condvar:wait()
    end
    return unpack(self.value)
end

---@class Channel
---@field private condvar Condvar
---@field private buffer any?
---@field is_closed boolean
local Channel = {}
Channel.__index = Channel
function Channel.new()
    return setmetatable({
        condvar = Condvar.new(),
        buffer = nil,
        is_closed = false,
    }, Channel)
end

function Channel:close()
    self.is_closed = true
end

---@async
function Channel:send(value)
    assert(not self.is_closed, "Channel is closed.")
    while self.buffer ~= nil do
        self.condvar:wait()
    end
    self.buffer = value
    self.condvar:notify()
    while self.buffer ~= nil do
        self.condvar:wait()
    end
end

---@async
function Channel:receive()
    assert(not self.is_closed, "Channel is closed.")
    while self.buffer == nil do
        self.condvar:wait()
    end
    local value = self.buffer
    self.buffer = nil
    self.condvar:notify()
    return value
end

---@async
function Channel:iter()
    return function()
        while not self.is_closed do
            return self:receive()
        end
    end
end

return {
    Condvar = Condvar,
    Semaphore = Semaphore,
    OneShotChannel = OneShotChannel,
    Channel = Channel,
}
