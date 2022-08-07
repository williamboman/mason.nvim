---@class EventEmitter
---@field private __event_handlers table<any, table<fun(), fun()>>
---@field private __event_handlers_once table<any, table<fun(), fun()>>
local EventEmitter = {}
EventEmitter.__index = EventEmitter

---@generic T
---@param obj T
---@return T
function EventEmitter.init(obj)
    obj.__event_handlers = {}
    obj.__event_handlers_once = {}
    return obj
end

---@param event any
function EventEmitter:emit(event, ...)
    if self.__event_handlers[event] then
        for handler in pairs(self.__event_handlers[event]) do
            pcall(handler, ...)
        end
    end
    if self.__event_handlers_once[event] then
        for handler in pairs(self.__event_handlers_once[event]) do
            pcall(handler, ...)
            self.__event_handlers_once[handler] = nil
        end
    end
end

---@param event any
---@param handler fun(payload: any)
function EventEmitter:on(event, handler)
    if not self.__event_handlers[event] then
        self.__event_handlers[event] = {}
    end
    self.__event_handlers[event][handler] = handler
end

---@param event any
---@param handler fun(payload: any)
function EventEmitter:once(event, handler)
    if not self.__event_handlers_once[event] then
        self.__event_handlers_once[event] = {}
    end
    self.__event_handlers_once[event][handler] = handler
end

---@param event any
---@param handler fun(payload: any)
function EventEmitter:off(event, handler)
    if vim.tbl_get(self.__event_handlers, { event, handler }) then
        self.__event_handlers[event][handler] = nil
        return true
    end
    return false
end

---@private
function EventEmitter:__clear_event_handlers()
    self.__event_handlers = {}
    self.__event_handlers_once = {}
end

return EventEmitter
