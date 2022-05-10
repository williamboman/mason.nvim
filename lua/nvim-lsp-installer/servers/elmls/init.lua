local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.core.managers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/elm-tooling/elm-language-server",
        languages = { "elm" },
        installer = npm.packages { "@elm-tooling/elm-language-server", "elm", "elm-test", "elm-format" },
        default_options = {
            cmd_env = npm.env(root_dir),
        },
    }
end
