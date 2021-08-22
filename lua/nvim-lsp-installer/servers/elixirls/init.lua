local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local shell = require "nvim-lsp-installer.installers.shell"

local root_dir = server.get_server_root_path "elixir"

return server.Server:new {
    name = "elixirls",
    root_dir = root_dir,
    installer = shell.raw [[
    wget -O elixir-ls.zip https://github.com/elixir-lsp/elixir-ls/releases/download/v0.7.0/elixir-ls.zip;
    unzip elixir-ls.zip -d elixir-ls;
    rm elixir-ls.zip;
    chmod +x elixir-ls/language_server.sh;
  ]],
    default_options = {
        cmd = { path.concat { root_dir, "elixir-ls", "language_server.sh" } },
    },
}
