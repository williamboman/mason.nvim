local server = require('nvim-lsp-installer.server')

local root_dir = server.get_server_root_path('json')

return server.Server:new {
    name = "jsonls",
    root_dir = root_dir,
    install_cmd = [[npm install vscode-json-languageserver-bin]],
    default_options = {
        cmd = { root_dir .. '/node_modules/.bin/json-languageserver', '--stdio' },
    },
}
