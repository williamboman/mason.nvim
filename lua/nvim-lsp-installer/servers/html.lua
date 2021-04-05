local server = require('nvim-lsp-installer.server')

local root_dir = server.get_server_root_path('html')

return server.Server:new {
    name = "html",
    root_dir = root_dir,
    install_cmd = [[npm install vscode-html-languageserver-bin]],
    default_options = {
        cmd = { root_dir .. '/node_modules/.bin/html-languageserver', '--stdio' },
    },
}
