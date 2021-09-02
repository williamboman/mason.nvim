local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "diagnosticls"

return server.Server:new {
	name = "diagnosticls",
	root_dir = root_dir,
	installer = npm.packages { "diagnostic-languageserver" },
	default_options = {
		cmd = { npm.executable(root_dir, "diagnostic-languageserver"), "--stdio" },
	},
}
