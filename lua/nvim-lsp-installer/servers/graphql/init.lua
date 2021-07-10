local util = require("lspconfig.util")

local server = require("nvim-lsp-installer.server")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("graphql")

return server.Server:new {
    name = "graphql",
    root_dir = root_dir,
    installer = npm.packages { "graphql-language-service-cli@latest",  "graphql" },
    default_options = {
        cmd = { npm.executable(root_dir, "graphql-lsp"), "server", "-m", "stream" },
        filetypes = { "typescriptreact", "javascriptreact", "graphql" },
        root_dir = util.root_pattern(
          -- Sourced from https://graphql-config.com/usage/ and https://git.io/Js2dt
          "package.json",
          "graphql.config.json",
          "graphql.config.js",
          "graphql.config.ts",
          "graphql.config.toml",
          "graphql.config.yaml",
          "graphql.config.yml",
          ".graphqlrc",
          ".graphqlrc.json",
          ".graphqlrc.toml",
          ".graphqlrc.yaml",
          ".graphqlrc.yml",
          ".graphqlrc.js",
          ".graphqlrc.ts"
        ),
    },
}
