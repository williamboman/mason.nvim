local server = require("nvim-lsp-installer.server")
local path = require("nvim-lsp-installer.path")
local zx = require("nvim-lsp-installer.installers.zx")

local root_dir = server.get_server_root_path("lua")

local uname_alias = {
    Darwin = "macOS",
}
local uname = vim.fn.system("uname"):gsub("%s+", "")
local bin_dir = uname_alias[uname] or uname

return server.Server:new {
    name = "sumneko_lua",
    root_dir = root_dir,
    install_cmd = zx.file("./install.mjs"),
    pre_install_check = function()
        if vim.fn.executable("ninja") ~= 1 then
            error("ninja not installed (see https://github.com/ninja-build/ninja/wiki/Pre-built-Ninja-packages)")
        end
    end,
    default_options = {
        cmd = { path.concat { root_dir, "bin", bin_dir, "lua-language-server" }, "-E", path.concat { root_dir, "main.lua" } },
        settings = {
            Lua = {
                diagnostics = {
                    -- Get the language server to recognize the `vim` global
                    globals = {"vim"}
                },
                workspace = {
                    -- Make the server aware of Neovim runtime files
                    library = {
                        [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                        [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
                    },
                    maxPreload = 10000
                }
            }
        },
    }
}
