local installer = require('nvim-lsp-installer.installer')
local capabilities = require('nvim-lsp-installer.capabilities')

local root_dir = installer.get_server_root_path('bash')

return installer.create_lsp_config_installer {
    name = "bashls",
    root_dir = root_dir,
    install_cmd = [[npm install bash-language-server@latest]],
    default_options = {
        cmd = { root_dir .. "/node_modules/.bin/bash-language-server", "start" },
        capabilities = capabilities.create(),
    },
}
