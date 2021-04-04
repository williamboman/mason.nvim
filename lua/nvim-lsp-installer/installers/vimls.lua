local installer = require('nvim-lsp-installer.installer')

local root_dir = installer.get_server_root_path('vim')

return installer.create_lsp_config_installer {
    name = "vimls",
    root_dir = root_dir,
    install_cmd = [[npm install vim-language-server@latest]],
    default_options = {
        cmd = { root_dir .. "/node_modules/.bin/vim-language-server", "--stdio" },
    }
}
