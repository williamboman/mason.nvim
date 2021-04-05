local installer = require('nvim-lsp-installer.installer')

local root_dir = installer.get_server_root_path('dockerfile')

return installer.Installer:new {
    name = 'dockerls',
    root_dir = root_dir,
    install_cmd = [[npm install dockerfile-language-server-nodejs@latest]],
    default_options = {
        cmd = { root_dir .. '/node_modules/.bin/docker-langserver', '--stdio' },
    },
}
