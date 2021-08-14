local extras = require "nvim-lsp-installer.extras.utils"

local M = {}

function M.rename_file(old, new)
    local old_uri = vim.uri_from_fname(old)
    local new_uri = vim.uri_from_fname(new)

    extras.send_client_request("tsserver", "workspace/executeCommand", {
        command = "_typescript.applyRenameFile",
        arguments = {
            {
                sourceUri = old_uri,
                targetUri = new_uri,
            },
        },
    })
end

function M.organize_imports(bufname)
    bufname = bufname or vim.api.nvim_buf_get_name(0)

    extras.send_client_request("tsserver", "workspace/executeCommand", {
        command = "_typescript.organizeImports",
        arguments = { bufname },
    })
end

return M
