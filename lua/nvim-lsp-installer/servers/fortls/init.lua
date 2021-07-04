local server = require("nvim-lsp-installer.server")
local path = require("nvim-lsp-installer.path")
local pip3 = require("nvim-lsp-installer.installers.pip3")

local root_dir = server.get_server_root_path("fortls")

return server.Server:new {
    name = "fortls",
    root_dir = root_dir,
    installer = pip3.packages { "fortran-language-server" },
    default_options = {
        cmd = { path.concat { root_dir, pip3.REL_INSTALL_DIR, "bin", "fortls" } },
    },
}

