local server = require('nvim-lsp-installer.server')

local root_dir = server.get_server_root_path('vim')

return server.Server:new {
    name = "vimls",
    root_dir = root_dir,
    install_cmd = [[npm install vim-language-server@latest]],
    default_options = {
        cmd = { root_dir .. "/node_modules/.bin/vim-language-server", "--stdio" },
    }
}
