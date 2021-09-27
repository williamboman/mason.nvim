local notify = require "nvim-lsp-installer.notify"

local M = {}

local registered_callbacks = {}

M.dispatch_server_ready = function(server)
    for _, callback in pairs(registered_callbacks) do
        local ok, err = pcall(callback, server)
        if not ok then
            notify(tostring(err), vim.log.levels.ERROR)
        end
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
