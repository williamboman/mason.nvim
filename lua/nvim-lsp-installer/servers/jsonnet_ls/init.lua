local path = require "nvim-lsp-installer.core.path"
local server = require "nvim-lsp-installer.server"
local go = require "nvim-lsp-installer.core.managers.go"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/grafana/jsonnet-language-server",
        installer = go.packages { "github.com/grafana/jsonnet-language-server" },
        default_options = {
            -- TODO: use env instead of cmd once https://github.com/neovim/nvim-lspconfig/pull/1559 is merged
            cmd = { path.concat { root_dir, "jsonnet-language-server" } },
        },
    }
end
