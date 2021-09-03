local M = {}

local function boolean_val(val)
    if type(val) == "nil" then
        return true
    elseif type(val) == "number" then
        return val == 1
    end
    return val and true or false
end

function M.allow_federated_servers()
    return boolean_val(vim.g.lsp_installer_allow_federated_servers)
end

function Test()
    print(boolean_val(vim.g.lsp_installer_allow_federated_servers))
end

return M
