local server = require "nvim-lsp-installer.server"
local github = require "nvim-lsp-installer.core.managers.github"
local pip3 = require "nvim-lsp-installer.core.managers.pip3"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "beancount" },
        homepage = "https://github.com/polarmutex/beancount-language-server",
        async = true,
        ---@param ctx InstallContext
        installer = function(ctx)
            local asset_file = assert(
                coalesce(
                    when(platform.is_mac, "beancount-language-server-macos-x64.zip"),
                    when(platform.is_linux and platform.arch == "x64", "beancount-language-server-linux-x64.zip"),
                    when(platform.is_win and platform.arch == "x64", "beancount-language-server-windows-x64.zip")
                ),
                "Unsupported platform"
            )
            github.unzip_release_file({
                repo = "polarmutex/beancount-language-server",
                asset_file = asset_file,
            }).with_receipt()

            local file_ext = platform.is_win and ".exe" or ""
            -- We rename the binary to conform with lspconfig
            ctx.fs:rename(("beancount-language-server%s"):format(file_ext), ("beancount-langserver%s"):format(file_ext))

            pip3.install { "beancount" }
            ctx.receipt:with_secondary_source(ctx.receipt.pip3 "beancount")
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir, pip3.venv_path(root_dir) },
            },
        },
    }
end
