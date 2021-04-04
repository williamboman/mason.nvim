local M = {}

local default_opts = {
    with_snippet_support = true,
}

function M.create(opts)
    opts = opts or default_opts
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = opts.with_snippet_support
    return capabilities
end

return M
