local installer = require('nvim-lsp-installer.installer')

local root_dir = installer.get_server_root_path('tsserver')

return installer.create_lsp_config_installer {
    name = "tsserver",
    root_dir = root_dir,
    install_cmd = [[npm install typescript-language-server]],
    default_options = {
        cmd = { root_dir .. '/node_modules/.bin/typescript-language-server', '--stdio' },
    },
}
