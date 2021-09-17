local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"

local bin_dir = Data.coalesce(
    Data.when(platform.is_mac, "macOS"),
    Data.when(platform.is_linux, "Linux"),
    Data.when(platform.is_win, "Windows")
)

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = {
            std.unzip_remote "https://github.com/sumneko/vscode-lua/releases/download/v2.3.6/lua-2.3.6.vsix",
            -- see https://github.com/sumneko/vscode-lua/pull/43
            std.chmod(
                "+x",
                { "extension/server/bin/macOS/lua-language-server", "extension/server/bin/Linux/lua-language-server" }
            ),
        },
        default_options = {
            cmd = {
                -- We need to provide a _full path_ to the executable (sumneko_lua uses it to determine... things)
                path.concat { root_dir, "extension", "server", "bin", bin_dir, "lua-language-server" },
                "-E",
                path.concat { root_dir, "extension", "server", "main.lua" },
            },
            settings = {
                Lua = {
                    diagnostics = {
                        -- Get the language server to recognize the `vim` global
                        globals = { "vim" },
                    },
                    workspace = {
                        -- Make the server aware of Neovim runtime files
                        library = {
                            [vim.fn.expand "$VIMRUNTIME/lua"] = true,
                            [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true,
                        },
                        maxPreload = 10000,
                    },
                },
            },
        },
    }
end
