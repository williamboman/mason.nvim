local server = require "nvim-lsp-installer.server"
local installers = require "nvim-lsp-installer.installers"
local context = require "nvim-lsp-installer.installers.context"
local pip3 = require "nvim-lsp-installer.installers.pip3"
local std = require "nvim-lsp-installer.installers.std"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    local file_ext = platform.is_win and ".exe" or ""
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "beancount" },
        homepage = "https://github.com/polarmutex/beancount-language-server",
        installer = {
            context.use_github_release_file(
                "polarmutex/beancount-language-server",
                coalesce(
                    when(platform.is_mac, "beancount-language-server-macos-x64.zip"),
                    when(platform.is_linux and platform.arch == "x64", "beancount-language-server-linux-x64.zip"),
                    when(platform.is_win and platform.arch == "x64", "beancount-language-server-windows-x64.zip")
                )
            ),
            context.capture(function(ctx)
                return installers.pipe {
                    std.unzip_remote(ctx.github_release_file),
                    -- We rename the binary to conform with lspconfig
                    std.rename(
                        ("beancount-language-server%s"):format(file_ext),
                        ("beancount-langserver%s"):format(file_ext)
                    ),
                }
            end),
            context.promote_install_dir(),
            installers.branch_context {
                context.set(function(ctx)
                    ctx.requested_server_version = nil
                end),
                pip3.packages { "beancount" },
            },
            context.receipt(function(receipt, ctx)
                receipt
                    :with_primary_source(receipt.github_release_file(ctx))
                    :with_secondary_source(receipt.pip3 "beancount")
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir, pip3.path(root_dir) },
            },
        },
    }
end
