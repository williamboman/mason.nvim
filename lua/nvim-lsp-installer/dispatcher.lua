local M = {}

local registered_callbacks = {}

---@param server Server
M.dispatch_server_ready = function(server)
    for _, callback in pairs(registered_callbacks) do
        local ok, err = pcall(callback, server)
        if not ok then
            vim.notify(tostring(err), vim.log.levels.ERROR)
        end
    end
end

---@param callback fun(server: Server)
function M.register_server_ready_callback(callback)
    registered_callbacks[callback] = callback
    return function()
        registered_callbacks[callback] = nil
    end
end

return M
