local server = require("nvim-lsp-installer.server")
local path = require("nvim-lsp-installer.path")
local go = require("nvim-lsp-installer.installers.go")

local root_dir = server.get_server_root_path("go")

return server.Server:new {
  name = "gopls",
  root_dir = root_dir,
  installer = go.packages { "golang.org/x/tools/gopls@latest" },
  default_options = {
    cmd = { go.executable(root_dir, "gopls") },
  }
}
