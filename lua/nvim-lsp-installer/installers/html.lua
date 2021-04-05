local installer = require('nvim-lsp-installer.installer')

local root_dir = installer.get_server_root_path('html')

return installer.Installer:new {
    name = "html",
    root_dir = root_dir,
    install_cmd = [[npm install vscode-html-languageserver-bin]],
    default_options = {
        cmd = { root_dir .. '/node_modules/.bin/html-languageserver', '--stdio' },
    },
}
