local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/elm-tooling/elm-language-server",
        languages = { "elm" },
        installer = npm.packages { "@elm-tooling/elm-language-server", "elm", "elm-test", "elm-format" },
        default_options = {
            cmd = { npm.executable(root_dir, "elm-language-server") },
            init_options = {
                elmPath = npm.executable(root_dir, "elm"),
                elmFormatPath = npm.executable(root_dir, "elm-format"),
                elmTestPath = npm.executable(root_dir, "elm-test"),
                elmAnalyseTrigger = "change",
            },
        },
    }
end
