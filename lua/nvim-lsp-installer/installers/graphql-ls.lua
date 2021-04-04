local util = require('lspconfig.util')

local installer = require('nvim-lsp-installer.installer')
local capabilities = require('nvim-lsp-installer.capabilities')

local root_dir = installer.get_server_root_path('graphql')

return installer.create_lsp_config_installer {
    name = "graphql",
    root_dir = root_dir,
    install_cmd = [[npm install graphql-language-service-cli@latest graphql]],
    default_options = {
        cmd = { root_dir .. "/node_modules/.bin/graphql-lsp", "server", "-m", "stream" },
        filetypes = { 'typescriptreact', 'javascriptreact', 'graphql' },
        root_dir = util.root_pattern('.git', '.graphqlrc'),
        capabilities = capabilities.create(),
    },
}
