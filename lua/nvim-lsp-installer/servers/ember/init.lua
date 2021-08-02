local server = require("nvim-lsp-installer.server")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("ember")

return server.Server:new {
    name = "ember",
    root_dir = root_dir,
    installer = npm.packages { "@lifeart/ember-language-server" },
    default_options = {
        cmd = { npm.executable(root_dir, "ember-language-server"), "--stdio" },
    },
}
