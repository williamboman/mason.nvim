local server = require("nvim-lsp-installer.server")
local path = require("nvim-lsp-installer.path")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("elm")

return server.Server:new {
  name = "elmls",
  root_dir = root_dir,
  installer = npm.packages { "elm", "elm-test", "elm-format", "@elm-tooling/elm-language-server" },
  default_options = {
    cmd = { path.concat { root_dir, "node_modules", ".bin", "elm-language-server" } },
  }
}
