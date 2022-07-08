local a = require "mason-core.async"

---@class Condvar
local Condvar = {}
Condvar.__index = Condvar

function Condvar.new()
    return setmetatable({ handles = {}, queue = {}, is_notifying = false }, Condvar)
end

---@async
function Condvar:wait()
    a.wait(function(resolve)
        if self.is_notifying then
            self.queue[resolve] = true
        else
            self.handles[resolve] = true
        end
    end)
end

function Condvar:notify_all()
    self.is_notifying = true
    for handle in pairs(self.handles) do
        handle()
    end
    self.handles = self.queue
    self.queue = {}
    self.is_notifying = false
end

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

return {
    Condvar = Condvar,
    Semaphore = Semaphore,
}
