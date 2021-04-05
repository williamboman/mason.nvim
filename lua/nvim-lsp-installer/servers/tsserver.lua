local server = require('nvim-lsp-installer.server')

local root_dir = server.get_server_root_path('tsserver')

return server.Server:new {
    name = "tsserver",
    root_dir = root_dir,
    install_cmd = [[npm install typescript-language-server]],
    default_options = {
        cmd = { root_dir .. '/node_modules/.bin/typescript-language-server', '--stdio' },
    },
}
