local server = require "nvim-lsp-installer.server"
local opam = require "nvim-lsp-installer.core.managers.opam"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/ocaml/ocaml-lsp",
        languages = { "ocaml" },
        installer = opam.packages { "ocaml-lsp-server" },
        default_options = {
            cmd_env = opam.env(root_dir),
        },
    }
end
