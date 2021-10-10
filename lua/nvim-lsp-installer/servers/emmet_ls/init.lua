local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/aca/emmet-ls",
        installer = npm.packages { "emmet-ls" },
        pre_setup = function()
            local lspconfig = require "lspconfig"
            local configs = require "lspconfig/configs"

            if not lspconfig.emmet_ls then
                configs.emmet_ls = {
                    default_config = {
                        cmd = { "emmet-ls", "--stdio" },
                        filetypes = { "html", "css" },
                        root_dir = function()
                            return vim.loop.cwd()
                        end,
                        settings = {},
                    },
                }
            end
        end,
        default_options = {
            cmd = { npm.executable(root_dir, "emmet-ls"), "--stdio" },
        },
    }
end
