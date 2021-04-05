local server = require('nvim-lsp-installer.server')

local root_dir = server.get_server_root_path('python')

return server.Server:new {
    name = "pyright",
    root_dir = root_dir,
    install_cmd = [[npm install pyright]],
    default_options = {
        cmd = { root_dir .. '/node_modules/.bin/pyright-langserver', '--stdio' },
        on_attach = server.common_on_attach,
    },
}
