local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"

local root_dir = server.get_server_root_path "elixir"

return server.Server:new {
    name = "elixirls",
    root_dir = root_dir,
    installer = {
        std.unzip_remote("https://github.com/elixir-lsp/elixir-ls/releases/download/v0.8.1/elixir-ls.zip", "elixir-ls"),
        std.chmod("+x", { "elixir-ls/language_server.sh" }),
    },
    default_options = {
        cmd = { path.concat { root_dir, "elixir-ls", "language_server.sh" } },
    },
}
