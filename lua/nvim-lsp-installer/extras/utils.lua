local M = {}

-- @deprecated
function M.send_client_request(client_name, ...)
    for _, client in pairs(vim.lsp.get_active_clients()) do
        if client.name == client_name then
            client.request(...)
        end
    end
end

return M
