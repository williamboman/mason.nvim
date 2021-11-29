# eslint

## Enabling document formatting

To make the `eslint` server respond to `textDocument/formatting` LSP requests, you need to manually enable this
setting. This is done when setting up the LSP server, like so:

```lua
local lsp_installer = require "nvim-lsp-installer"

function common_on_attach(client, bufnr) 
  -- add your code here
end

lsp_installer.on_server_ready(function (server)
    local opts = {
        on_attach = common_on_attach,
    }

    if server.name == "eslint" then
        opts.on_attach = function (client, bufnr)
            -- neovim's LSP client does not currently support dynamic capabilities registration, so we need to set
            -- the resolved capabilities of the eslint server ourselves!
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

This will make `eslint` respond to formatting requests, for example when triggered through:

-   `:lua vim.lsp.buf.formatting()`
-   `:lua vim.lsp.buf.formatting_seq_sync()`
-   `:lua vim.lsp.buf.formatting_sync()`

## Eslint in projects that use pnp

To allow the `eslint` server to resolve eslint and eslint plugins in a project that uses yarn 2/pnp, you need to manually change the
command used to run the server. This is done when setting up the LSP server, like so:

```lua
lsp_installer.on_server_ready(function (server)
    local opts = {
        on_attach = common_on_attach,
    }

    if server.name == "eslint" then
      local default_opts = server:get_default_options()
      opts.cmd = vim.list_extend({"yarn", "node"}, default_opts.cmd)
    end

    server:setup(opts)
end)
```

*NOTE*: You will have to install the [`eslint` package](https://www.npmjs.com/package/eslint) either locally or globally for the server to run successfully.
