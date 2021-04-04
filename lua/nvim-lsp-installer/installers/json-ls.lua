local installer = require('nvim-lsp-installer.installer')
local capabilities = require('nvim-lsp-installer.capabilities')

local root_dir = installer.get_server_root_path('json')

return installer.create_lsp_config_installer {
    name = "jsonls",
    root_dir = root_dir,
    install_cmd = [[npm install vscode-json-languageserver-bin]],
    default_options = {
        cmd = { root_dir .. '/node_modules/.bin/json-languageserver', '--stdio' },
        capabilities = capabilities.create(),
    },
}
