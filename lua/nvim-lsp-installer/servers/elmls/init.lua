local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "elm"

return server.Server:new {
    name = "elmls",
    root_dir = root_dir,
    installer = npm.packages { "elm", "elm-test", "elm-format", "@elm-tooling/elm-language-server" },
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
