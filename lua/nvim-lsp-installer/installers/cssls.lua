local installer = require('nvim-lsp-installer.installer')

local root_dir = installer.get_server_root_path('css')

return installer.create_lsp_config_installer {
    name = 'cssls',
    root_dir = root_dir,
    install_cmd = [[npm install vscode-css-languageserver-bin]],
    default_options = {
        cmd = { root_dir .. '/node_modules/.bin/css-languageserver', '--stdio' },
    },
}
