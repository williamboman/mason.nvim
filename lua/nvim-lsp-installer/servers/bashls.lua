local server = require('nvim-lsp-installer.server')

local root_dir = server.get_server_root_path('bash')

return server.Server:new {
    name = "bashls",
    root_dir = root_dir,
    install_cmd = [[npm install bash-language-server@latest]],
    default_options = {
        cmd = { root_dir .. "/node_modules/.bin/bash-language-server", "start" },
    },
}
