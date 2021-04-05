local server = require('nvim-lsp-installer.server')

local root_dir = server.get_server_root_path('css')

return server.Server:new {
    name = 'cssls',
    root_dir = root_dir,
    install_cmd = [[npm install vscode-css-languageserver-bin]],
    default_options = {
        cmd = { root_dir .. '/node_modules/.bin/css-languageserver', '--stdio' },
    },
}
