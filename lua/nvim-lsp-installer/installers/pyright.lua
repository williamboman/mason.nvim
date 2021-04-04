local installer = require('nvim-lsp-installer.installer')
local capabilities = require('nvim-lsp-installer.capabilities')

local root_dir = installer.get_server_root_path('python')

return installer.create_lsp_config_installer {
    name = "pyright",
    root_dir = root_dir,
    install_cmd = [[npm install pyright]],
    default_options = {
        cmd = { root_dir .. '/node_modules/.bin/pyright-langserver', '--stdio' },
        capabilities = capabilities.create(),
        on_attach = installer.common_on_attach,
    },
}
