local M = {}

local registered_callbacks = {}

M.dispatch_server_ready = function(server)
    for i = 1, #registered_callbacks do
        registered_callbacks[i](server)
    end
end

local idx = 0
function M.register_server_ready_callback(callback)
    local key = idx + 1
    registered_callbacks[("%d"):format(key)] = callback
    return function()
        table.remove(registered_callbacks, key)
    end
end

return M
