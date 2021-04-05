local server = require('nvim-lsp-installer.server')

local root_dir = server.get_server_root_path('yaml')

return server.Server:new {
    name = "yamlls",
    root_dir = root_dir,
    install_cmd = [[npm install yaml-language-server]],
    default_options = {
        cmd = { root_dir .. '/node_modules/.bin/yaml-language-server', '--stdio' },
    }
}
