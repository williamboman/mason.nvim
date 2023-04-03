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

function Condvar:notify_all()
    for _, handle in ipairs(self.handles) do
        pcall(handle)
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

return {
    Condvar = Condvar,
    Semaphore = Semaphore,
    OneShotChannel = OneShotChannel,
}
