local server = require("nvim-lsp-installer.server")
local path = require("nvim-lsp-installer.path")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("elm")

local bin_dir = path.concat { root_dir, "node_modules", ".bin" }

local function bin(executable)
    return path.concat { bin_dir, executable }
end

return server.Server:new {
  name = "elmls",
  root_dir = root_dir,
  installer = npm.packages { "elm", "elm-test", "elm-format", "@elm-tooling/elm-language-server" },
  default_options = {
    cmd = { bin("elm-language-server") },
    init_options = {
      elmPath = bin("elm"),
      elmFormatPath = bin("elm-format"),
      elmTestPath = bin("elm-test"),
      elmAnalyseTrigger = "change",
    },
  }
}
