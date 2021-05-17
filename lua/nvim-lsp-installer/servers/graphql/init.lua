local util = require("lspconfig.util")

local server = require("nvim-lsp-installer.server")
local path = require("nvim-lsp-installer.path")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("graphql")

return server.Server:new {
    name = "graphql",
    root_dir = root_dir,
    installer = npm.packages { "graphql-language-service-cli@latest",  "graphql" },
    default_options = {
        cmd = { path.concat { root_dir, "node_modules", ".bin", "graphql-lsp" }, "server", "-m", "stream" },
        filetypes = { "typescriptreact", "javascriptreact", "graphql" },
        root_dir = util.root_pattern(".git", ".graphqlrc"),
    },
}
