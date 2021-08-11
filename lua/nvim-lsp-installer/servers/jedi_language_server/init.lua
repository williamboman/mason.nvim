local server = require("nvim-lsp-installer.server")
local pip3 = require("nvim-lsp-installer.installers.pip3")

local root_dir = server.get_server_root_path("jedi_language_server")

return server.Server:new {
    name = "jedi_language_server",
    root_dir = root_dir,
    installer = pip3.packages { "jedi-language-server" },
    default_options = {
        cmd = { pip3.executable(root_dir, "jedi-language-server") },
    },
}
