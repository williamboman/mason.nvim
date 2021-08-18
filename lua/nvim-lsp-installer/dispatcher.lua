local M = {}

local registered_callbacks = {}

function M.dispatch_server_ready(server)
    for _, callback in pairs(registered_callbacks) do
        callback(server)
    end
end

local idx = 0
function M.register_server_ready_callback(callback)
    local key = idx + 1
    registered_callbacks[("%d"):format(key)] = callback
    return function ()
        table.remove(registered_callbacks, key)
    end
end


return M
