# eslintls

## Enabling document formatting

To make the `eslintls` server respond to `textDocument/formatting` LSP requests, you need to manually enable this
setting. This is done when setting up the LSP server, like so:

```lua
local lsp_installer = require "nvim-lsp-installer"

function common_on_attach(client, bufnr) ... end

for _, server in pairs(installed_servers) do
    local opts = {
        on_attach = common_on_attach,
    }

    if server.name == "eslintls" then
        -- neovim's LSP client does not currently support dynamic capabilities registration, so we need to set
        -- the resolved capabilities of the eslintls server ourselves!
        client.resolved_capabilities.document_formatting = true
        opts.settings = {
            format = { enable = true }, -- this will enable formatting
        }
    end

    server:setup(opts)
end
```

This will make `eslintls` respond to formatting requests, for example when triggered through:

-   `:lua vim.lsp.buf.formatting()`
-   `:lua vim.lsp.buf.formatting_seq_sync()`
-   `:lua vim.lsp.buf.formatting_sync()`
