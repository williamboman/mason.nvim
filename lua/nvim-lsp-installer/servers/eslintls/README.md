# eslintls

## Enabling document formatting

To make the `eslintls` server respond to `textDocument/formatting` LSP requests, you need to manually enable this
setting. This is done when setting up the LSP server, like so:

```lua
local lsp_installer = require "nvim-lsp-installer"

function common_on_attach(client, bufnr) ... end

lsp_installer.on_server_ready(function (server)
    local opts = {
        on_attach = common_on_attach,
    }

    if server.name == "eslintls" then
        opts.on_attach = function (client, bufnr)
            -- neovim's LSP client does not currently support dynamic capabilities registration, so we need to set
            -- the resolved capabilities of the eslintls server ourselves!
            client.resolved_capabilities.document_formatting = true
            common_on_attach(client, bufnr)
        end
        opts.settings = {
            format = { enable = true }, -- this will enable formatting
        }
    end

    server:setup(opts)
end)
```

This will make `eslintls` respond to formatting requests, for example when triggered through:

-   `:lua vim.lsp.buf.formatting()`
-   `:lua vim.lsp.buf.formatting_seq_sync()`
-   `:lua vim.lsp.buf.formatting_sync()`
