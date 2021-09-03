local M = {}

local function boolean_val(val, default)
    if type(val) == "nil" then
        return default
    elseif type(val) == "number" then
        return val == 1
    end
    return val and true or false
end

function M.allow_federated_servers()
    return boolean_val(vim.g.lsp_installer_allow_federated_servers, true)
end

return M
