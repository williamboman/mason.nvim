local server = require('nvim-lsp-installer.server')

local root_dir = server.get_server_root_path('dockerfile')

return server.Server:new {
    name = 'dockerls',
    root_dir = root_dir,
    install_cmd = [[npm install dockerfile-language-server-nodejs@latest]],
    default_options = {
        cmd = { root_dir .. '/node_modules/.bin/docker-langserver', '--stdio' },
    },
}
