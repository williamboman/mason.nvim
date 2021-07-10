local server = require("nvim-lsp-installer.server")
local pip3 = require("nvim-lsp-installer.installers.pip3")

local root_dir = server.get_server_root_path("fortls")

return server.Server:new {
    name = "fortls",
    root_dir = root_dir,
    installer = pip3.packages { "fortran-language-server" },
    default_options = {
        cmd = { pip3.executable(root_dir, "fortls") },
    },
}

